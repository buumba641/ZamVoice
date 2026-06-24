import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../audio/audio_metadata_reader.dart';
import '../audio/audio_recorder.dart';
import '../audio/audio_uploader.dart';
import '../inference/hallucination_filter.dart';
import '../inference/whisper_service.dart';
import '../models/chat_message.dart';
import '../orchestration/whisper_queue.dart';
import '../orchestration/whisper_task.dart';
import '../validation/audio_validator.dart';
import 'app_state.dart';
import 'app_ui_state.dart';

class AppController extends StateNotifier<AppUiState> {
  AppController({
    required AppAudioRecorder recorder,
    required AudioUploader uploader,
    required AudioMetadataReader metadataReader,
    required AudioValidator validator,
    required WhisperQueue queue,
    required WhisperService whisperService,
    required HallucinationFilter hallucinationFilter,
    required Uuid uuid,
  })  : _recorder = recorder,
        _uploader = uploader,
        _metadataReader = metadataReader,
        _validator = validator,
        _queue = queue,
        _whisperService = whisperService,
        _hallucinationFilter = hallucinationFilter,
        _uuid = uuid,
        super(AppUiState.initial()) {
    _queue.setHandler(_processTask);
  }

  final AppAudioRecorder _recorder;
  final AudioUploader _uploader;
  final AudioMetadataReader _metadataReader;
  final AudioValidator _validator;
  final WhisperQueue _queue;
  final WhisperService _whisperService;
  final HallucinationFilter _hallucinationFilter;
  final Uuid _uuid;

  DateTime? _recordStart;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted || !(await _recorder.hasPermission())) {
      _setError('Microphone access is required to record audio.');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/recording_${_uuid.v4()}.wav';
    _recordStart = DateTime.now();
    state = state.copyWith(status: AppState.recording, errorText: null);
    await _recorder.start(path);
  }

  Future<void> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) {
      _setError('Recording failed. Please try again.');
      return;
    }

    final duration = await _metadataReader.readDuration(path) ??
        DateTime.now().difference(_recordStart ?? DateTime.now());
    await _handleAudio(path: path, duration: duration, isUpload: false);
  }

  Future<void> uploadAudio() async {
    state = state.copyWith(status: AppState.uploading, errorText: null);
    final path = await _uploader.pickAudioPath();
    if (path == null) {
      state = state.copyWith(status: AppState.idle);
      return;
    }

    final duration = await _metadataReader.readDuration(path);
    if (duration == null) {
      _setError('Unable to read audio duration.');
      return;
    }

    await _handleAudio(path: path, duration: duration, isUpload: true);
  }

  void setTranslateMode(bool value) {
    state = state.copyWith(translateMode: value);
  }

  Future<void> _handleAudio({
    required String path,
    required Duration duration,
    required bool isUpload,
  }) async {
    final validation = _validator.validateDuration(duration);
    if (!validation.isValid) {
      _setError(validation.rejectReason ?? 'Audio is invalid.');
      return;
    }

    final messageType =
        isUpload ? ChatMessageType.uploadedAudio : ChatMessageType.userAudio;
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      type: messageType,
      text: isUpload ? 'Uploaded audio' : 'Recorded audio',
      timestamp: DateTime.now(),
      audioPath: path,
      duration: duration,
    );

    final updated = [...state.messages, userMessage];
    state = state.copyWith(
      status: AppState.processingWhisper,
      messages: updated,
      processingText: validation.warningText,
      errorText: null,
    );

    final task = WhisperTask(
      id: _uuid.v4(),
      audioPath: path,
      duration: duration,
      isTranslation: state.translateMode,
    );
    _queue.enqueue(task);
  }

  Future<void> _processTask(WhisperTask task) async {
    final String result;
    try {
      result = await _whisperService.run(
        audioPath: task.audioPath,
        translate: task.isTranslation,
      );
    } catch (error) {
      _setError(error.toString());
      return;
    } finally {
      // Clean up the temporary recording file after inference completes.
      _cleanupTempFile(task.audioPath);
    }

    if (_hallucinationFilter.isHallucinated(result)) {
      _setError('Audio not recognized within the model\'s trained vocabulary.');
      return;
    }

    final type = task.isTranslation
        ? ChatMessageType.translation
        : ChatMessageType.transcription;
    final message = ChatMessage(
      id: _uuid.v4(),
      type: type,
      text: result,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      status: AppState.idle,
      messages: [...state.messages, message],
      processingText: null,
      errorText: null,
    );
  }

  void clearError() {
    state = state.copyWith(status: AppState.idle, errorText: null);
  }

  void _setError(String message) {
    final errorMessage = ChatMessage(
      id: _uuid.v4(),
      type: ChatMessageType.system,
      text: message,
      timestamp: DateTime.now(),
      isError: true,
    );
    state = state.copyWith(
      status: AppState.error,
      messages: [...state.messages, errorMessage],
      processingText: null,
      errorText: message,
    );
  }

  void _cleanupTempFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {
      // Non-critical — ignore cleanup failures.
    }
  }
}
