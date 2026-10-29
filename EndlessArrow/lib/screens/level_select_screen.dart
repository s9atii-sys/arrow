import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ad_service.dart';
import '../levels/level_repository.dart';
import '../services/progress_service.dart';
import '../widgets/common_widgets.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const _pageSize = 30;
  late final int _totalPages;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _totalPages = (LevelRepository.totalLevels / _pageSize).ceil();
    final unlocked = ProgressService.instance.unlockedLevel;
    _currentPage = ((unlocked - 1) / _pageSize).floor();
  }

  @override
  Widget build(BuildContext context) {
    final start = _currentPage * _pageSize + 1;
    final end = (start + _pageSize - 1).clamp(1, LevelRepository.totalLevels);
    final unlocked = ProgressService.instance.unlockedLevel;

    return PastelBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.navy,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'SELECT LEVEL',
            style: GoogleFonts.fredoka(
              color: AppTheme.navy,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: _currentPage > 0
                          ? AppTheme.navy
                          : AppTheme.navy.withValues(alpha: 0.25),
                      size: 32,
                    ),
                  ),
                  Text(
                    'Levels $start – $end',
                    style: GoogleFonts.fredoka(
                      color: AppTheme.navy.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _currentPage < _totalPages - 1
                          ? AppTheme.navy
                          : AppTheme.navy.withValues(alpha: 0.25),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: end - start + 1,
                itemBuilder: (context, index) {
                  final levelId = start + index;
                  final isLocked = levelId > unlocked;
                  final stars = ProgressService.instance.starsFor(levelId);

                  return _LevelTile(
                    levelId: levelId,
                    locked: isLocked,
                    stars: stars,
                    onTap: isLocked
                        ? null
                        : () {
                            AdService.instance.showInterstitialThen(() {
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      GameScreen(levelId: levelId),
                                ),
                              );
                            });
                          },
                  );
                },
              ),
            ),
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: TextButton.icon(
                  onPressed: () async {
                    await ProgressService.instance.unlockAllLevels(
                      LevelRepository.totalLevels,
                    );
                    if (!context.mounted) return;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'All ${LevelRepository.totalLevels} levels unlocked (debug)',
                          style: GoogleFonts.fredoka(),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: Text(
                    'Unlock all levels',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.purple,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.levelId,
    required this.locked,
    required this.stars,
    this.onTap,
  });

  final int levelId;
  final bool locked;
  final int stars;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: locked
            ? BoxDecoration(
                color: const Color(0xFFCBD1EA),
                borderRadius: BorderRadius.circular(16),
              )
            : AppTheme.whiteCard(radius: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (locked)
              Icon(
                Icons.lock_rounded,
                color: AppTheme.navy.withValues(alpha: 0.35),
                size: 22,
              )
            else
              Text(
                '$levelId',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
                ),
              ),
            const SizedBox(height: 6),
            if (!locked)
              StarRating(stars: stars, size: 12)
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
