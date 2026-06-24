import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../audio/audio_metadata_reader.dart';
import '../audio/audio_recorder.dart';
import '../audio/audio_uploader.dart';
import '../inference/hallucination_filter.dart';
import '../core/constants.dart';
import '../inference/model_path_resolver.dart';
import '../inference/whisper_ffi_service.dart';
import '../orchestration/whisper_queue.dart';
import '../validation/audio_validator.dart';
import 'app_controller.dart';
import 'app_ui_state.dart';
import 'tts_settings_controller.dart';
import 'tts_settings_state.dart';
import '../storage/secure_storage_service.dart';

final appControllerProvider =
		StateNotifierProvider<AppController, AppUiState>((ref) {
	final recorder = AppAudioRecorder();
	return AppController(
		recorder: recorder,
		uploader: AudioUploader(),
		metadataReader: AudioMetadataReader(),
		validator: AudioValidator(),
		queue: WhisperQueue(),
		whisperService: WhisperFfiService(
			modelResolver: ModelPathResolver(),
			modelFileName: modelFileName,
		),
		hallucinationFilter: HallucinationFilter(),
		uuid: const Uuid(),
	);
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
	return SecureStorageService(const FlutterSecureStorage());
});

final ttsSettingsControllerProvider =
		StateNotifierProvider<TtsSettingsController, TtsSettingsState>((ref) {
	return TtsSettingsController(ref.read(secureStorageProvider));
});

