import 'package:nyanjatoenglish_voice/src/inference/hallucination_filter.dart';
import 'package:nyanjatoenglish_voice/src/validation/audio_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HallucinationFilter', () {
    final filter = HallucinationFilter();

    test('empty text is hallucinated', () {
      expect(filter.isHallucinated(''), isTrue);
      expect(filter.isHallucinated('   '), isTrue);
    });

    test('short phrases pass through', () {
      expect(filter.isHallucinated('hello'), isFalse);
      expect(filter.isHallucinated('yes please'), isFalse);
    });

    test('highly repetitive text is flagged', () {
      // 6+ words with < 30% uniqueness
      expect(
        filter.isHallucinated('go go go go go go go go go go'),
        isTrue,
      );
    });

    test('normal sentences pass through', () {
      expect(
        filter.isHallucinated('I would like to go to the market today'),
        isFalse,
      );
    });
  });

  group('AudioValidator', () {
    final validator = AudioValidator();

    test('zero-duration audio is rejected', () {
      final result = validator.validateDuration(Duration.zero);
      expect(result.isValid, isFalse);
    });

    test('audio under 6 minutes is accepted', () {
      final result =
          validator.validateDuration(const Duration(minutes: 1, seconds: 30));
      expect(result.isValid, isTrue);
    });

    test('audio over 6 minutes is rejected', () {
      final result =
          validator.validateDuration(const Duration(minutes: 6, seconds: 1));
      expect(result.isValid, isFalse);
    });

    test('audio between 2-6 minutes shows warning', () {
      final result =
          validator.validateDuration(const Duration(minutes: 3));
      expect(result.isValid, isTrue);
      expect(result.warningText, contains('few seconds'));
    });
  });
}
