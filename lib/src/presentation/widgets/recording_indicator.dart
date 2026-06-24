import 'package:flutter/material.dart';

/// Lightweight recording-active indicator: a pulsing green dot + elapsed timer.
///
/// Uses a single [AnimationController] driving a [FadeTransition] — no Lottie,
/// no shimmer, no blur. The dot simply fades between 40 % and 100 % opacity.
class RecordingIndicator extends StatefulWidget {
  const RecordingIndicator({super.key, required this.elapsed});

  /// How long the recording has been running.
  final Duration elapsed;

  @override
  State<RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  static const _dotColor = Color(0xFF00C853);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.4,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.elapsed.inMinutes;
    final s = (widget.elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _pulse,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$m:$s',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _dotColor,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Recording…',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}
