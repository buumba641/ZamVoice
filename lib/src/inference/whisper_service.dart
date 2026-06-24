abstract class WhisperService {
  Future<String> run({
    required String audioPath,
    required bool translate,
  });
}
