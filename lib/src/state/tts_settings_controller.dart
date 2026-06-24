import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_service.dart';
import 'tts_settings_state.dart';

class TtsSettingsController extends StateNotifier<TtsSettingsState> {
  TtsSettingsController(this._storage) : super(TtsSettingsState.initial());

  final SecureStorageService _storage;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final key = await _storage.readElevenLabsKey();
      state = state.copyWith(isLoading: false, apiKey: key);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load API key.',
      );
    }
  }

  Future<void> save(String value) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _storage.writeElevenLabsKey(value);
      state = state.copyWith(isLoading: false, apiKey: value);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to save API key.',
      );
    }
  }
}
