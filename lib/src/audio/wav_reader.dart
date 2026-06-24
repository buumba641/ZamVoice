import 'dart:io';
import 'dart:typed_data';

/// Reads 16-bit PCM WAV files and produces float32 sample arrays
/// suitable for whisper.cpp inference.
class WavReader {
  /// Reads a WAV file at [path] and returns normalised float32 PCM samples.
  ///
  /// The WAV must be 16-bit signed-integer PCM (the format the
  /// [AppAudioRecorder] and [AudioFormatConverter] produce).
  /// Samples are normalised to the range \[-1.0, 1.0\].
  static Float32List readAsFloat32(String path) {
    final bytes = File(path).readAsBytesSync();
    if (bytes.length < 44) {
      throw StateError('File too small to be a valid WAV: $path');
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    // Verify RIFF header.
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    if (riff != 'RIFF') {
      throw StateError('Not a RIFF file: $path');
    }

    // Walk chunks to find 'data'.
    int dataOffset = 0;
    int dataSize = 0;
    int offset = 12; // skip RIFF header (4) + file size (4) + WAVE id (4)

    while (offset < bytes.length - 8) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = byteData.getUint32(offset + 4, Endian.little);

      if (chunkId == 'data') {
        dataOffset = offset + 8;
        dataSize = chunkSize;
        break;
      }

      // Advance past this chunk (header + payload, 2-byte aligned).
      offset += 8 + chunkSize;
      if (chunkSize.isOdd) offset++;
    }

    if (dataOffset == 0 || dataSize == 0) {
      throw StateError('No data chunk found in WAV file: $path');
    }

    // Clamp dataSize to the actual remaining bytes in the file.
    final available = bytes.length - dataOffset;
    if (dataSize > available) dataSize = available;

    // Convert int16 PCM → float32.
    final numSamples = dataSize ~/ 2;
    final samples = Float32List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      final int16Value = byteData.getInt16(dataOffset + i * 2, Endian.little);
      samples[i] = int16Value / 32768.0;
    }

    return samples;
  }
}
