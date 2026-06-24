import '../core/constants.dart';
import 'audio_validation_result.dart';

class AudioValidator {
  AudioValidationResult validateDuration(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds <= minProcessingSeconds) {
      return const AudioValidationResult(
        isValid: false,
        rejectReason: 'Audio duration is invalid.',
      );
    }

    if (seconds > longPathMaxSeconds) {
      return const AudioValidationResult(
        isValid: false,
        rejectReason: 'Audio exceeds the maximum supported duration of 6 minutes.',
      );
    }

    if (seconds >= fastPathMaxSeconds) {
      return const AudioValidationResult(
        isValid: true,
        warningText: 'Processing this will take a few seconds...',
      );
    }

    return const AudioValidationResult(
      isValid: true,
      warningText: 'Processing...',
    );
  }
}
