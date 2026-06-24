import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Resolves and caches the model file path.
///
/// On first launch the GGUF model is copied from Flutter assets into the
/// app's documents directory. Subsequent calls return the cached path
/// immediately without any file I/O.
class ModelPathResolver {
  String? _cachedPath;

  Future<String> resolveModelPath(String fileName) async {
    if (_cachedPath != null) {
      return _cachedPath!;
    }

    final dir = await getApplicationDocumentsDirectory();
    final targetPath = '${dir.path}/$fileName';
    final targetFile = File(targetPath);

    if (!await targetFile.exists()) {
      // First launch — extract the model from the bundled Flutter assets.
      final assetKey = 'assets/models/$fileName';
      final data = await rootBundle.load(assetKey);
      await targetFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }

    _cachedPath = targetPath;
    return targetPath;
  }
}
