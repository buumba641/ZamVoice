import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Animated splash screen shown on app launch.
///
/// Displays the "ZamVoice" brand name, a short description, and a pulsing
/// microphone icon. After [_kSplashDuration] it navigates to [HomeScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _kSplashDuration = Duration(milliseconds: 2500);
  static const _accent = Color(0xFF00C853);

  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // Fade-in for the whole content.
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    // Pulsing glow on the mic icon.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Navigate after splash duration.
    Future.delayed(_kSplashDuration, _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── pulsing mic icon ──
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  return Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.15 * _pulse.value),
                          blurRadius: 32 * _pulse.value,
                          spreadRadius: 4 * _pulse.value,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.mic_rounded,
                      size: 44,
                      color: _accent.withValues(alpha: 0.6 + 0.4 * _pulse.value),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // ── app name ──
              const Text(
                'ZamVoice',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              // ── description ──
              Text(
                'Speak Nyanja, hear English.\nOffline voice translation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              // ── loading indicator ──
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _accent.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
