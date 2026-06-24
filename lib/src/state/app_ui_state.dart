import '../models/chat_message.dart';
import 'app_state.dart';

class AppUiState {
  const AppUiState({
    required this.status,
    required this.messages,
    required this.translateMode,
    this.processingText,
    this.errorText,
  });

  final AppState status;
  final List<ChatMessage> messages;
  final bool translateMode;
  final String? processingText;
  final String? errorText;

  AppUiState copyWith({
    AppState? status,
    List<ChatMessage>? messages,
    bool? translateMode,
    String? processingText,
    String? errorText,
  }) {
    return AppUiState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      translateMode: translateMode ?? this.translateMode,
      processingText: processingText,
      errorText: errorText,
    );
  }

  factory AppUiState.initial() {
    return const AppUiState(
      status: AppState.idle,
      messages: [],
      translateMode: true,
    );
  }
}
