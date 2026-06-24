import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hold-to-record FAB with a fill-progress arc drawn via [CustomPaint].
///
/// While the user holds down, a green arc sweeps 360 ° over [maxDuration].
/// Uses [GestureDetector.onLongPressStart] / [onLongPressEnd] to trigger
/// recording start/stop callbacks.
///
/// No external packages — just a single [CustomPainter].
class RecordingFab extends StatefulWidget {
  const RecordingFab({
    super.key,
    required this.isRecording,
    required this.isDisabled,
    required this.onRecordStart,
    required this.onRecordStop,
    this.maxDuration = const Duration(minutes: 6),
    this.size = 68,
  });

  final bool isRecording;
  final bool isDisabled;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;
  final Duration maxDuration;
  final double size;

  @override
  State<RecordingFab> createState() => _RecordingFabState();
}

class _RecordingFabState extends State<RecordingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  static const _accent = Color(0xFF00C853);
  static const _bgIdle = Color(0xFF1A1A1A);
  static const _bgActive = Color(0xFF0D2E1A);

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: widget.maxDuration,
    );
  }

  @override
  void didUpdateWidget(covariant RecordingFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync animation with external recording state.
    if (!widget.isRecording && _progress.isAnimating) {
      _progress.reset();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _handleStart(LongPressStartDetails _) {
    if (widget.isDisabled) return;
    _progress.forward(from: 0);
    widget.onRecordStart();
  }

  void _handleEnd(LongPressEndDetails _) {
    if (!widget.isRecording) return;
    _progress.stop();
    _progress.reset();
    widget.onRecordStop();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;

    return GestureDetector(
      onLongPressStart: _handleStart,
      onLongPressEnd: _handleEnd,
      child: SizedBox(
        width: s,
        height: s,
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, child) {
            return CustomPaint(
              painter: _ArcPainter(
                progress: _progress.value,
                arcColor: _accent,
                trackColor: _accent.withValues(alpha: 0.15),
                strokeWidth: 3.5,
              ),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isRecording ? _bgActive : _bgIdle,
              border: Border.all(
                color: _accent.withValues(alpha: widget.isRecording ? 0.8 : 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                widget.isRecording ? Icons.stop_rounded : Icons.mic,
                color: _accent,
                size: s * 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a circular arc indicating how much of [progress] (0–1) has elapsed.
class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.arcColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color arcColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final deflated = rect.deflate(strokeWidth / 2);

    // Track (full circle, faint)
    canvas.drawArc(
      deflated,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    if (progress <= 0) return;

    // Progress arc (starts at top, i.e. -π/2)
    canvas.drawArc(
      deflated,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = arcColor,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
