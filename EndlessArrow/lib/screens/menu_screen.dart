import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../services/progress_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/common_widgets.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _openGame(BuildContext context, int levelId) {
    AdService.instance.showInterstitialThen(() {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(levelId: levelId),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ProgressService.instance.unlockedLevel;

    return PastelBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const GameLogo(),
                        const SizedBox(height: 56),
                        ChunkyButton(
                          label: 'PLAY',
                          blue: true,
                          fontSize: 34,
                          width: 280,
                          onPressed: () => _openGame(context, unlocked),
                        ),
                        const SizedBox(height: 18),
                        ChunkyButton(
                          label: 'LEVELS',
                          fontSize: 18,
                          width: 200,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LevelSelectScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        ChunkyButton(
                          label: 'SETTINGS',
                          coral: true,
                          fontSize: 18,
                          width: 200,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
