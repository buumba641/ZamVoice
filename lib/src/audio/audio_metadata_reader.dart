import 'package:just_audio/just_audio.dart';

class AudioMetadataReader {
  Future<Duration?> readDuration(String path) async {
    final player = AudioPlayer();
    try {
      await player.setFilePath(path);
      return player.duration;
    } finally {
      await player.dispose();
    }
  }
}
