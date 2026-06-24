class TtsSettingsState {
  const TtsSettingsState({
    required this.isLoading,
    this.apiKey,
    this.errorMessage,
  });

  final bool isLoading;
  final String? apiKey;
  final String? errorMessage;

  TtsSettingsState copyWith({
    bool? isLoading,
    String? apiKey,
    String? errorMessage,
  }) {
    return TtsSettingsState(
      isLoading: isLoading ?? this.isLoading,
      apiKey: apiKey ?? this.apiKey,
      errorMessage: errorMessage,
    );
  }

  factory TtsSettingsState.initial() {
    return const TtsSettingsState(isLoading: false);
  }
}
