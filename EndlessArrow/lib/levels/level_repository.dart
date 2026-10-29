import 'puzzle_generator.dart';
import '../models/level.dart';

class LevelRepository {
  LevelRepository._();

  static const int totalLevels = 420;

  static final Map<int, LevelDefinition> _cache = {};

  static LevelDefinition getLevel(int levelId) =>
      _cache[levelId] ??= PuzzleGenerator.generate(levelId);

  static List<LevelDefinition> getPage(int page, {int pageSize = 20}) {
    final start = page * pageSize + 1;
    return List.generate(
      pageSize,
      (i) => getLevel(start + i),
    ).where((l) => l.id <= totalLevels).toList();
  }
}
