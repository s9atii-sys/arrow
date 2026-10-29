// ignore_for_file: avoid_print
import 'package:arrow_challenge/levels/level_repository.dart';

void main() {
  for (final id in [1, 2, 5, 10, 30, 60, 100, 200, 300, 420]) {
    final level = LevelRepository.getLevel(id);
    final dirs = <String, int>{'up': 0, 'down': 0, 'left': 0, 'right': 0};
    var straight = 0;
    var bentL = 0;
    var bentU = 0;
    for (final snake in level.snakes) {
      final cells = snake.cells;
      final (hr, hc) = cells.last;
      final (pr, pc) = cells[cells.length - 2];
      if (hr < pr) dirs['up'] = dirs['up']! + 1;
      if (hr > pr) dirs['down'] = dirs['down']! + 1;
      if (hc < pc) dirs['left'] = dirs['left']! + 1;
      if (hc > pc) dirs['right'] = dirs['right']! + 1;

      var turns = 0;
      for (var i = 2; i < cells.length; i++) {
        final d1 = (cells[i - 1].$1 - cells[i - 2].$1, cells[i - 1].$2 - cells[i - 2].$2);
        final d2 = (cells[i].$1 - cells[i - 1].$1, cells[i].$2 - cells[i - 1].$2);
        if (d1 != d2) turns++;
      }
      if (turns == 0) straight++;
      if (turns == 1) bentL++;
      if (turns >= 2) bentU++;
    }
    print('level $id: ${level.snakes.length} arrows | '
        'up ${dirs['up']} down ${dirs['down']} left ${dirs['left']} right ${dirs['right']} | '
        'straight $straight, L-bend $bentL, U-bend $bentU');
  }
}
