// ignore_for_file: avoid_print
import 'package:arrow_challenge/levels/level_repository.dart';
import 'package:arrow_challenge/logic/puzzle_engine.dart';

void main() {
  var failures = 0;
  final sw = Stopwatch()..start();

  for (var id = 1; id <= 420; id++) {
    final level = LevelRepository.getLevel(id);
    final engine = PuzzleEngine.fromLevel(level);

    var initialMovable = 0;
    var movableSum = 0;
    var steps = 0;

    while (!engine.isComplete) {
      int? firstMovable;
      var movable = 0;
      for (final snake in engine.snakes) {
        if (engine.previewMove(snake.id).didMove) {
          movable++;
          firstMovable ??= snake.id;
        }
      }
      if (firstMovable == null) break;
      if (steps == 0) initialMovable = movable;
      movableSum += movable;
      steps++;
      engine.tryMove(firstMovable);
    }

    final cells = level.snakes.fold<int>(0, (sum, s) => sum + s.cells.length);
    final fill = cells / (level.rows * level.cols);

    if (!engine.isComplete) {
      failures++;
      print('LEVEL $id NOT SOLVABLE');
      continue;
    }

    if (id <= 5 || id == 10 || id == 15 || id == 20 || id == 30 ||
        id == 50 || id == 75 || id == 100 || id % 60 == 0) {
      final avg = (movableSum / steps).toStringAsFixed(1);
      final turns = level.snakes.isEmpty
          ? 0.0
          : level.snakes.fold<int>(0, (s, a) {
              if (a.cells.length < 3) return s;
              var t = 0;
              for (var i = 2; i < a.cells.length; i++) {
                final d1r = a.cells[i - 1].$1 - a.cells[i - 2].$1;
                final d1c = a.cells[i - 1].$2 - a.cells[i - 2].$2;
                final d2r = a.cells[i].$1 - a.cells[i - 1].$1;
                final d2c = a.cells[i].$2 - a.cells[i - 1].$2;
                if (d1r != d2r || d1c != d2c) t++;
              }
              return s + t;
            }) /
              level.snakes.length;
      final heads = <String, int>{'↑': 0, '↓': 0, '←': 0, '→': 0};
      for (final s in level.snakes) {
        if (s.cells.length < 2) continue;
        final (hr, hc) = s.cells.last;
        final (pr, pc) = s.cells[s.cells.length - 2];
        final key = hr < pr
            ? '↑'
            : hr > pr
                ? '↓'
                : hc < pc
                    ? '←'
                    : '→';
        heads[key] = heads[key]! + 1;
      }
      print('level $id: ${level.rows}x${level.cols}, '
          '${level.snakes.length} arrows, fill ${(fill * 100).round()}%, '
          'pattern ${level.patternKey}, '
          'open at start: $initialMovable, avg open: $avg, '
          'avg turns: ${turns.toStringAsFixed(1)}, '
          'dirs ↑${heads['↑']} ↓${heads['↓']} ←${heads['←']} →${heads['→']}');
    }
  }

  sw.stop();
  print(failures == 0 ? 'ALL 420 LEVELS SOLVABLE' : '$failures failures');
  print('generated + verified in ${sw.elapsedMilliseconds}ms '
      '(${(sw.elapsedMilliseconds / 420).toStringAsFixed(1)}ms per level)');
}
