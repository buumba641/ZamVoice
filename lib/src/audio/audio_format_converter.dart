import 'package:audio_converter_native/audio_converter_native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Converts mp3, m4a, and other audio formats to 16 kHz mono WAV
/// for Whisper inference using native platform APIs.
class AudioFormatConverter {
  static const _uuid = Uuid();

  /// Returns the path to a 16 kHz mono WAV file.
  ///
  /// If [inputPath] is already a .wav file the path is returned as-is
  /// (the recorder already outputs the correct format).
  /// Otherwise the file is converted using native platform codecs.
  Future<String> ensureWhisperFormat(String inputPath) async {
    final lower = inputPath.toLowerCase();
    if (lower.endsWith('.wav')) {
      return inputPath;
    }

    final dir = await getTemporaryDirectory();
    final outputPath = '${dir.path}/converted_${_uuid.v4()}.wav';

    final result = await AudioConverterService.instance.convertToWAV(
      inputPath: inputPath,
      outputPath: outputPath,
      sampleRate: 16000,
      channels: 1,
    );

    if (!result.success) {
      throw StateError(
        'Audio conversion failed: ${result.error ?? "unknown error"}',
      );
    }

    return result.outputPath ?? outputPath;
  }
}
