typedef Cell = (int row, int col);

class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.rows,
    required this.cols,
    required this.snakes,
    this.parMoves = 0,
    this.difficulty = LevelDifficulty.easy,
    this.patternKey = '',
  });

  final int id;
  final int rows;
  final int cols;
  final List<LevelSnake> snakes;
  final int parMoves;
  final LevelDifficulty difficulty;

  /// Shape / combination used to generate this board (for docs & debugging).
  final String patternKey;
}

/// A winding arrow occupying several cells. Cells are ordered tail -> head;
/// the head direction is derived from the last two cells.
class LevelSnake {
  const LevelSnake(this.cells);

  final List<Cell> cells;
}

enum LevelDifficulty { easy, medium, hard, expert }

extension LevelDifficultyLabel on LevelDifficulty {
  String get label => switch (this) {
        LevelDifficulty.easy => 'Easy',
        LevelDifficulty.medium => 'Medium',
        LevelDifficulty.hard => 'Hard',
        LevelDifficulty.expert => 'Expert',
      };
}

extension LevelTimeLimit on LevelDefinition {
  /// Time budget follows the estimated finish time: about 1.7 seconds per
  /// arrow early on, tightening toward ~1.0s per arrow at high levels,
  /// plus a small buffer to read the board.
  int get timeLimitSeconds {
    final perArrow = (1.7 - (id / 420) * 0.7).clamp(1.0, 1.7);
    final estimate = snakes.length * perArrow + 10;
    return estimate.round().clamp(40, 200);
  }
}
