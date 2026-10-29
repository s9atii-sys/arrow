import 'dart:math';

import '../models/level.dart';
import 'puzzle_shape.dart';

/// Progressive difficulty for a level id.
///
/// Level 1 already fills the board with a dense maze of long winding arrows.
/// Later levels grow the grid, add more arrows, longer corridors, more turns,
/// and tighter interlocking. [packCap] is the real placement ceiling so
/// leftover holes keep filling after [maxSnakes] is reached.
class PuzzleDifficulty {
  const PuzzleDifficulty({
    required this.rows,
    required this.cols,
    required this.minSnakes,
    required this.maxSnakes,
    required this.minLen,
    required this.maxLen,
    required this.fill,
    required this.comboCount,
    required this.decoyChance,
    required this.inset,
    required this.turnBias,
    required this.blockDepth,
    required this.allowed,
    required this.difficulty,
  });

  final int rows;
  final int cols;
  final int minSnakes;
  final int maxSnakes;
  final int minLen;
  final int maxLen;
  final double fill;
  final int comboCount;
  final double decoyChance;
  final int inset;
  final double turnBias;
  final int blockDepth;
  final List<PuzzleShapeId> allowed;
  final LevelDifficulty difficulty;

  /// Hard ceiling for packing. High enough that exit-ray blockers and
  /// leftover crumbs can fill the board instead of stopping at [maxSnakes].
  int get packCap => min(160, max(maxSnakes + 40, (rows * cols / 2.4).floor()));

  /// Portrait-friendly boards. Higher levels use more cells so arrows can
  /// stay long while the count still climbs.
  static const _boards = [
    (22, 13), // 286
    (23, 13), // 299
    (24, 13), // 312
    (25, 14), // 350
    (26, 14), // 364
    (27, 15), // 405
  ];

  static PuzzleDifficulty of(int id) {
    final t = ((id - 1) / 420).clamp(0.0, 1.0);

    final minSnakes = (50 + (id - 1) * 0.08).round().clamp(50, 82);
    final maxSnakes = minSnakes + 28;

    final minLen = 4;
    final maxLen = (10 + (t * 6).round()).clamp(10, 16);

    final fill = (0.96 + t * 0.03).clamp(0.96, 0.99);
    final boardIndex =
        ((id - 1) / (420 / _boards.length)).floor().clamp(0, _boards.length - 1);
    final rows = _boards[boardIndex].$1;
    final cols = _boards[boardIndex].$2;

    final comboCount = id <= 4 ? 1 : (id <= 20 ? 2 : 3);
    final allowed = switch (id) {
      <= 8 => PuzzleShapeCatalog.intro,
      <= 18 => PuzzleShapeCatalog.early,
      <= 40 => PuzzleShapeCatalog.mid,
      <= 70 => PuzzleShapeCatalog.tricky,
      <= 150 => PuzzleShapeCatalog.hard,
      _ => PuzzleShapeCatalog.expert,
    };
    final difficulty = switch (id) {
      <= 15 => LevelDifficulty.easy,
      <= 60 => LevelDifficulty.medium,
      <= 150 => LevelDifficulty.hard,
      _ => LevelDifficulty.expert,
    };

    return PuzzleDifficulty(
      rows: rows,
      cols: cols,
      minSnakes: minSnakes,
      maxSnakes: maxSnakes,
      minLen: minLen,
      maxLen: maxLen,
      fill: fill,
      comboCount: comboCount,
      decoyChance: min(0.85, 0.4 + t * 0.5),
      inset: 0,
      turnBias: 0.52 + t * 0.26,
      blockDepth: 10 + (t * 8).round(),
      allowed: allowed,
      difficulty: difficulty,
    );
  }
}
