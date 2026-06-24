class AudioValidationResult {
  const AudioValidationResult({
    required this.isValid,
    this.warningText,
    this.rejectReason,
  });

  final bool isValid;
  final String? warningText;
  final String? rejectReason;
}
