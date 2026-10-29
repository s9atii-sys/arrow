// ignore_for_file: avoid_print
import 'package:arrow_challenge/levels/level_repository.dart';

void main() {
  for (final id in [1, 5, 10, 15, 20, 30, 50, 75, 100]) {
    final level = LevelRepository.getLevel(id);
    print('--- LEVEL $id ${level.rows}x${level.cols} '
        '${level.snakes.length} arrows  ${level.patternKey} ---');
    final grid = List.generate(
      level.rows,
      (_) => List.filled(level.cols, ' . '),
    );
    var label = 0;
    for (final snake in level.snakes) {
      final ch = String.fromCharCode(65 + (label++ % 26));
      for (var i = 0; i < snake.cells.length; i++) {
        final (r, c) = snake.cells[i];
        final isHead = i == snake.cells.length - 1;
        grid[r][c] = isHead ? '<$ch>' : ' $ch ';
      }
    }
    for (final row in grid) {
      print(row.join());
    }
    print('');
  }
}
