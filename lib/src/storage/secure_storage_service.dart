import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readElevenLabsKey() => _storage.read(key: 'elevenlabs_api_key');

  Future<void> writeElevenLabsKey(String value) async {
    await _storage.write(key: 'elevenlabs_api_key', value: value);
  }
}
