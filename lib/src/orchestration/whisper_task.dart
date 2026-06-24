class WhisperTask {
  WhisperTask({
    required this.id,
    required this.audioPath,
    required this.duration,
    required this.isTranslation,
  });

  final String id;
  final String audioPath;
  final Duration duration;
  final bool isTranslation;
}
