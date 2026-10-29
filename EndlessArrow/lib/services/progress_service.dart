import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  ProgressService._();
  static final instance = ProgressService._();

  static const _unlockedKey = 'unlocked_level';
  static const _starsPrefix = 'stars_';
  static const _hintsKey = 'hints_remaining';

  int _unlockedLevel = 1;
  int _hintsRemaining = 5;
  final Map<int, int> _stars = {};

  int get unlockedLevel => _unlockedLevel;
  int get hintsRemaining => _hintsRemaining;

  int starsFor(int levelId) => _stars[levelId] ?? 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _unlockedLevel = prefs.getInt(_unlockedKey) ?? 1;
    _hintsRemaining = prefs.getInt(_hintsKey) ?? 5;

    _stars.clear();
    for (var i = 1; i <= _unlockedLevel + 5; i++) {
      final stars = prefs.getInt('$_starsPrefix$i');
      if (stars != null) _stars[i] = stars;
    }
  }

  Future<void> completeLevel({
    required int levelId,
    required int moves,
    required int parMoves,
    required int blocked,
  }) async {
    final stars = _calculateStars(moves: moves, par: parMoves, blocked: blocked);
    final existing = _stars[levelId] ?? 0;
    if (stars > existing) {
      _stars[levelId] = stars;
    }
    if (levelId >= _unlockedLevel) {
      _unlockedLevel = levelId + 1;
    }
    await _persist();
  }

  int _calculateStars({
    required int moves,
    required int par,
    required int blocked,
  }) {
    if (blocked > 2) return 1;
    if (par <= 0) return moves <= 3 ? 3 : 2;
    if (moves <= par) return 3;
    if (moves <= par + 2) return 2;
    return 1;
  }

  Future<bool> useHint() async {
    if (_hintsRemaining <= 0) return false;
    _hintsRemaining--;
    await _persist();
    return true;
  }

  Future<void> addHints(int count) async {
    _hintsRemaining += count;
    await _persist();
  }

  /// Debug-only: unlock every level up to [maxLevel].
  Future<void> unlockAllLevels(int maxLevel) async {
    assert(kDebugMode, 'unlockAllLevels is only available in debug mode');
    if (!kDebugMode) return;

    if (_unlockedLevel < maxLevel) {
      _unlockedLevel = maxLevel;
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unlockedKey, _unlockedLevel);
    await prefs.setInt(_hintsKey, _hintsRemaining);
    for (final entry in _stars.entries) {
      await prefs.setInt('$_starsPrefix${entry.key}', entry.value);
    }
  }
}