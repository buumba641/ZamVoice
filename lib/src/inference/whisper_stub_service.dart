import 'whisper_service.dart';

class WhisperStubService implements WhisperService {
  @override
  Future<String> run({
    required String audioPath,
    required bool translate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return translate
        ? 'Translation placeholder (wire whisper_ggml_plus).'
        : 'Transcription placeholder (wire whisper_ggml_plus).';
  }
}
