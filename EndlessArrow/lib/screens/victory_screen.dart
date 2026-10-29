import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../levels/level_repository.dart';
import '../widgets/common_widgets.dart';
import 'game_screen.dart';
import 'menu_screen.dart';

class VictoryScreen extends StatelessWidget {
  const VictoryScreen({
    super.key,
    required this.levelId,
    required this.moves,
    required this.parMoves,
    required this.elapsedSeconds,
    required this.blocked,
  });

  final int levelId;
  final int moves;
  final int parMoves;
  final int elapsedSeconds;
  final int blocked;

  int get _stars {
    if (blocked > 2) return 1;
    if (parMoves <= 0) return moves <= 3 ? 3 : 2;
    if (moves <= parMoves) return 3;
    if (moves <= parMoves + 2) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final hasNext = levelId < LevelRepository.totalLevels;

    return PastelBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.success.withValues(alpha: 0.15),
                    border: Border.all(color: AppTheme.success, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppTheme.success,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'LEVEL $levelId CLEARED!',
                  style: GoogleFonts.fredoka(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navy,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                StarRating(stars: _stars, size: 40),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.whiteCard(radius: 24),
                  child: Column(
                    children: [
                      _StatRow(label: 'Moves', value: '$moves'),
                      const Divider(color: Color(0xFFE4E8F7), height: 24),
                      _StatRow(label: 'Time', value: '${elapsedSeconds}s'),
                      const Divider(color: Color(0xFFE4E8F7), height: 24),
                      _StatRow(label: 'Mistakes', value: '$blocked'),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                if (hasNext)
                  ChunkyButton(
                    label: 'NEXT LEVEL',
                    blue: true,
                    fontSize: 24,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => GameScreen(levelId: levelId + 1),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 14),
                ChunkyButton(
                  label: 'MENU',
                  fontSize: 17,
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const MenuScreen(),
                      ),
                      (_) => false,
                    );
                  },
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.fredoka(
            color: AppTheme.navy.withValues(alpha: 0.55),
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.fredoka(
            color: AppTheme.navy,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
