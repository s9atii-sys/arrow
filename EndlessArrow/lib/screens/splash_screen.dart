import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/common_widgets.dart';
import 'menu_screen.dart';

const _tips = [
  'Tap an arrow to slide it along its path.',
  'Only arrows with a clear exit can move.',
  'Wrong taps shake the board and cost a heart.',
  'Beat the timer to clear every level.',
  'Trace an arrow\'s path before you tap it.',
  'Remove blocking arrows first to open the way.',
  'Every level gets a little tougher — stay sharp!',
  'Plan your moves — most arrows are traps.',
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final String _tip;

  @override
  void initState() {
    super.initState();
    _tip = _tips[Random().nextInt(_tips.length)];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward().then((_) => _goToMenu());
  }

  void _goToMenu() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const MenuScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PastelBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const GameLogo(),
                  const SizedBox(height: 48),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _tip,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              color: AppTheme.navy.withValues(alpha: 0.72),
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 280,
                            child: SplashProgressBar(
                              progress: _controller.value,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
