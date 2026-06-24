import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../audio/audio_format_converter.dart';
import '../audio/wav_reader.dart';
import 'model_path_resolver.dart';
import 'whisper_service.dart';

/// Whisper inference service using direct Dart FFI to a self-compiled
/// `libwhisper_bridge.so`.
///
/// The entire native Whisper lifecycle (init, infer, free) runs inside a
/// **long-lived background isolate** to guarantee the main (UI) thread is
/// never blocked — eliminating Android ANR kills even for large audio files.
///
/// Communication uses [SendPort] / [ReceivePort] message passing with
/// simple tagged maps so that all data crossing the isolate boundary
/// consists only of primitives and typed-data lists.
class WhisperFfiService implements WhisperService {
  WhisperFfiService({
    required this.modelResolver,
    required this.modelFileName,
  });

  final ModelPathResolver modelResolver;
  final String modelFileName;
  final AudioFormatConverter _converter = AudioFormatConverter();

  /// Port used to send commands to the worker isolate.
  SendPort? _workerSendPort;

  /// The worker isolate handle (kept for cleanup).
  Isolate? _workerIsolate;

  /// Whether the model has been initialised inside the worker.
  bool _modelReady = false;

  /// Completer that resolves when the worker isolate is up and its
  /// [SendPort] has been received.
  Completer<void>? _spawnCompleter;

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  /// Ensures the background worker isolate is running and the Whisper model
  /// is loaded.  Safe to call multiple times — subsequent calls are no-ops.
  Future<void> _ensureInitialized() async {
    // 1. Spawn the isolate if it hasn't been created yet.
    if (_workerIsolate == null) {
      _spawnCompleter = Completer<void>();
      final receivePort = ReceivePort();

      _workerIsolate = await Isolate.spawn(
        _workerEntryPoint,
        receivePort.sendPort,
      );

      // The first message from the worker is its SendPort.
      _workerSendPort = await receivePort.first as SendPort;
      _spawnCompleter!.complete();
    } else {
      // If spawn is in progress from another concurrent call, wait.
      await _spawnCompleter?.future;
    }

    // 2. Send the 'init' command if the model hasn't been loaded yet.
    if (!_modelReady) {
      final modelPath = await modelResolver.resolveModelPath(modelFileName);
      final modelFile = File(modelPath);
      if (!await modelFile.exists()) {
        throw StateError('Model file not found at $modelPath');
      }

      final response = await _sendCommand({'cmd': 'init', 'modelPath': modelPath});
      if (response['error'] != null) {
        throw StateError(response['error'] as String);
      }
      _modelReady = true;
    }
  }

  // -----------------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------------

  @override
  Future<String> run({
    required String audioPath,
    required bool translate,
  }) async {
    await _ensureInitialized();

    // Convert non-WAV uploads (mp3, m4a) to 16 kHz mono WAV.
    final wavPath = await _converter.ensureWhisperFormat(audioPath);

    try {
      // Read WAV → float32 samples on the main isolate (pure Dart, fast).
      final samples = WavReader.readAsFloat32(wavPath);

      // Send samples + params to the worker; inference happens entirely
      // off the main thread.
      final response = await _sendCommand({
        'cmd': 'infer',
        'samples': samples,          // Float32List — transferable
        'translate': translate,
      });

      if (response['error'] != null) {
        throw StateError(response['error'] as String);
      }
      return (response['result'] as String).trim();
    } finally {
      if (wavPath != audioPath) {
        try {
          await File(wavPath).delete();
        } catch (_) {}
      }
    }
  }

  /// Releases the native whisper context and kills the worker isolate.
  void dispose() {
    if (_workerSendPort != null) {
      // Fire-and-forget — the isolate will free the context and exit.
      final replyPort = ReceivePort();
      _workerSendPort!.send({'cmd': 'free', 'replyTo': replyPort.sendPort});
      replyPort.close();
    }
    _workerIsolate?.kill(priority: Isolate.beforeNextEvent);
    _workerIsolate = null;
    _workerSendPort = null;
    _modelReady = false;
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /// Sends a command map to the worker and waits for a single reply.
  Future<Map<String, dynamic>> _sendCommand(Map<String, dynamic> command) async {
    final replyPort = ReceivePort();
    command['replyTo'] = replyPort.sendPort;
    _workerSendPort!.send(command);
    final result = await replyPort.first;
    return result as Map<String, dynamic>;
  }
}

// ===========================================================================
// Background worker isolate — runs entirely off the main thread.
// ===========================================================================

/// Entry point for the long-lived worker isolate.
///
/// Receives a [SendPort] from the main isolate, sends back its own
/// [SendPort], then loops forever handling 'init', 'infer', and 'free'
/// commands.
void _workerEntryPoint(SendPort mainSendPort) {
  final workerReceivePort = ReceivePort();
  // Send our port back so the main isolate can talk to us.
  mainSendPort.send(workerReceivePort.sendPort);

  Pointer<Void>? ctx;
  DynamicLibrary? lib;

  // Lookup function pointers (lazily, after 'init').
  Pointer<Void> Function(Pointer<Utf8>)? bridgeInit;
  Pointer<Utf8> Function(Pointer<Void>, Pointer<Float>, int, int)? bridgeInfer;
  void Function(Pointer<Void>)? bridgeFree;

  workerReceivePort.listen((message) {
    final cmd = message as Map<String, dynamic>;
    final replyTo = cmd['replyTo'] as SendPort;

    switch (cmd['cmd'] as String) {
      // -------------------------------------------------------------------
      case 'init':
        try {
          lib = DynamicLibrary.open('libwhisper_bridge.so');

          bridgeInit = lib!.lookupFunction<
              Pointer<Void> Function(Pointer<Utf8>),
              Pointer<Void> Function(Pointer<Utf8>)>('bridge_init');

          bridgeInfer = lib!.lookupFunction<
              Pointer<Utf8> Function(Pointer<Void>, Pointer<Float>, Int32, Int32),
              Pointer<Utf8> Function(Pointer<Void>, Pointer<Float>, int, int)>(
              'bridge_infer');

          bridgeFree = lib!.lookupFunction<
              Void Function(Pointer<Void>),
              void Function(Pointer<Void>)>('bridge_free');

          final modelPath = cmd['modelPath'] as String;
          final pathPtr = modelPath.toNativeUtf8();
          try {
            ctx = bridgeInit!(pathPtr);
          } finally {
            malloc.free(pathPtr);
          }

          if (ctx == null || ctx == nullptr) {
            replyTo.send({'error': 'Failed to initialise whisper context'});
          } else {
            replyTo.send({'ok': true});
          }
        } catch (e) {
          replyTo.send({'error': e.toString()});
        }
        break;

      // -------------------------------------------------------------------
      case 'infer':
        try {
          if (ctx == null || ctx == nullptr || bridgeInfer == null) {
            replyTo.send({'error': 'Whisper not initialised'});
            break;
          }

          final samples = cmd['samples'] as Float32List;
          final translate = (cmd['translate'] as bool) ? 1 : 0;

          // Allocate native memory and copy samples across.
          final nativeSamples = malloc<Float>(samples.length);
          try {
            nativeSamples.asTypedList(samples.length).setAll(0, samples);

            // This is the long-running blocking call — safe here because
            // we are NOT on the main thread.
            final resultPtr =
                bridgeInfer!(ctx!, nativeSamples, samples.length, translate);
            final result = resultPtr.toDartString();
            replyTo.send({'result': result});
          } finally {
            malloc.free(nativeSamples);
          }
        } catch (e) {
          replyTo.send({'error': e.toString()});
        }
        break;

      // -------------------------------------------------------------------
      case 'free':
        if (ctx != null && ctx != nullptr && bridgeFree != null) {
          bridgeFree!(ctx!);
          ctx = null;
        }
        replyTo.send({'ok': true});
        break;
    }
  });
}
