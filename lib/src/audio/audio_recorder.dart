import 'package:record/record.dart' as rec;

/// Thin wrapper around the `record` package's [rec.AudioRecorder].
///
/// Configures recording to output 16 kHz mono PCM WAV — the exact format
/// Whisper expects.
class AppAudioRecorder {
  AppAudioRecorder() : _recorder = rec.AudioRecorder();

  final rec.AudioRecorder _recorder;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start(String path) async {
    await _recorder.start(
      const rec.RecordConfig(
        encoder: rec.AudioEncoder.wav,
        bitRate: 256000,
        sampleRate: 16000,
        numChannels: 1, // Whisper expects mono 16 kHz PCM WAV
      ),
      path: path,
    );
  }

  Future<String?> stop() => _recorder.stop();

  Future<void> dispose() => _recorder.dispose();
}
