enum ChatMessageType {
  userAudio,
  uploadedAudio,
  translation,
  transcription,
  tts,
  system,
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.type,
    required this.text,
    required this.timestamp,
    this.audioPath,
    this.duration,
    this.isError = false,
  });

  final String id;
  final ChatMessageType type;
  final String text;
  final DateTime timestamp;
  final String? audioPath;
  final Duration? duration;
  final bool isError;
}
