import '../models/direction.dart';
import '../models/level.dart';

enum MoveResult { moved, blocked, alreadyEmpty, won }

class MoveOutcome {
  const MoveOutcome({
    required this.result,
    this.rayCells = 0,
    this.removedId,
  });

  final MoveResult result;

  /// Number of free cells between the head and the board edge along the
  /// head's direction. Used to size the slide-out animation.
  final int rayCells;
  final int? removedId;

  bool get didMove => result == MoveResult.moved || result == MoveResult.won;
}

/// Runtime state of one winding arrow. Cells are ordered tail -> head.
class ArrowSnake {
  ArrowSnake({required this.id, required this.cells})
      : assert(cells.length >= 2);

  final int id;
  final List<Cell> cells;

  Cell get head => cells.last;

  Direction get heading {
    final (hr, hc) = cells.last;
    final (pr, pc) = cells[cells.length - 2];
    if (hr < pr) return Direction.up;
    if (hr > pr) return Direction.down;
    if (hc < pc) return Direction.left;
    return Direction.right;
  }
}

class PuzzleEngine {
  PuzzleEngine.fromLevel(LevelDefinition level)
      : rows = level.rows,
        cols = level.cols,
        _snakes = level.snakes
            .asMap()
            .entries
            .map((e) => ArrowSnake(id: e.key, cells: List.of(e.value.cells)))
            .toList();

  final int rows;
  final int cols;
  final List<ArrowSnake> _snakes;
  int moveCount = 0;
  int blockedCount = 0;

  List<ArrowSnake> get snakes => List.unmodifiable(_snakes);

  bool get isComplete => _snakes.isEmpty;

  bool isInside(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  ArrowSnake? snakeAt(int row, int col) {
    for (final snake in _snakes) {
      for (final (r, c) in snake.cells) {
        if (r == row && c == col) return snake;
      }
    }
    return null;
  }

  ArrowSnake? snakeById(int id) {
    for (final snake in _snakes) {
      if (snake.id == id) return snake;
    }
    return null;
  }

  /// A snake can leave the board when every cell from its head to the edge
  /// (along the head direction) is free.
  MoveOutcome previewMove(int snakeId) {
    final snake = snakeById(snakeId);
    if (snake == null) {
      return const MoveOutcome(result: MoveResult.alreadyEmpty);
    }

    final (dr, dc) = snake.heading.delta;
    var (r, c) = snake.head;
    r += dr;
    c += dc;
    var ray = 0;

    while (isInside(r, c)) {
      if (snakeAt(r, c) != null) {
        return const MoveOutcome(result: MoveResult.blocked);
      }
      ray++;
      r += dr;
      c += dc;
    }

    return MoveOutcome(
      result: MoveResult.moved,
      rayCells: ray,
      removedId: snakeId,
    );
  }

  MoveOutcome tryMove(int snakeId) {
    final outcome = previewMove(snakeId);
    if (outcome.result == MoveResult.blocked) {
      blockedCount++;
      return outcome;
    }
    if (outcome.result == MoveResult.alreadyEmpty) return outcome;

    moveCount++;
    _snakes.removeWhere((s) => s.id == snakeId);

    return MoveOutcome(
      result: _snakes.isEmpty ? MoveResult.won : MoveResult.moved,
      rayCells: outcome.rayCells,
      removedId: snakeId,
    );
  }

  int? findHintSnakeId() {
    for (final snake in _snakes) {
      if (previewMove(snake.id).didMove) return snake.id;
    }
    return null;
  }
}
