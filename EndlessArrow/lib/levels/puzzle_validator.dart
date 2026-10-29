import '../models/level.dart';

class PuzzleValidation {
  const PuzzleValidation({
    required this.solvable,
    required this.initialMovable,
    required this.avgMovable,
    required this.steps,
  });

  final bool solvable;
  final int initialMovable;
  final double avgMovable;
  final int steps;

  /// Lower is harder (fewer legal moves while solving). Heavy weight on the
  /// opening position: a board with only a handful of free arrows forces the
  /// player to hunt for the right starting move.
  double get easeScore {
    if (!solvable) return double.infinity;
    return initialMovable * 3 + avgMovable * 1.5;
  }
}

/// Fast solvability check on a flat occupancy grid. Boards now hold 100+
/// arrows, so the simulation avoids per-cell snake scans entirely.
class PuzzleValidator {
  PuzzleValidator._();

  static PuzzleValidation validate(LevelDefinition level) {
    final rows = level.rows;
    final cols = level.cols;
    final bodies = [for (final s in level.snakes) s.cells];

    // owner[r * cols + c] = snake index, or -1 when empty.
    final owner = List<int>.filled(rows * cols, -1);
    for (var i = 0; i < bodies.length; i++) {
      for (final (r, c) in bodies[i]) {
        owner[r * cols + c] = i;
      }
    }

    bool movable(int i) {
      final body = bodies[i];
      final (hr, hc) = body.last;
      final (pr, pc) = body[body.length - 2];
      final dr = (hr - pr).sign;
      final dc = (hc - pc).sign;
      var r = hr + dr;
      var c = hc + dc;
      while (r >= 0 && r < rows && c >= 0 && c < cols) {
        if (owner[r * cols + c] != -1) return false;
        r += dr;
        c += dc;
      }
      return true;
    }

    final alive = List<bool>.filled(bodies.length, true);
    var remaining = bodies.length;
    var initialMovable = 0;
    var movableSum = 0;
    var steps = 0;

    while (remaining > 0) {
      var count = 0;
      var first = -1;
      for (var i = 0; i < bodies.length; i++) {
        if (!alive[i]) continue;
        if (movable(i)) {
          count++;
          if (first == -1) first = i;
        }
      }
      if (first == -1) {
        return PuzzleValidation(
          solvable: false,
          initialMovable: initialMovable,
          avgMovable: 0,
          steps: steps,
        );
      }
      if (steps == 0) initialMovable = count;
      movableSum += count;
      steps++;
      alive[first] = false;
      remaining--;
      for (final (r, c) in bodies[first]) {
        owner[r * cols + c] = -1;
      }
    }

    return PuzzleValidation(
      solvable: true,
      initialMovable: initialMovable,
      avgMovable: steps == 0 ? 0 : movableSum / steps,
      steps: steps,
    );
  }
}
