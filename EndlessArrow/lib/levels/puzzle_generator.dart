import 'dart:math';

import '../models/direction.dart';
import '../models/level.dart';
import 'puzzle_difficulty.dart';
import 'puzzle_shape.dart';
import 'puzzle_validator.dart';

/// Picks shape combinations that stay away from recent levels' families.
class PuzzleRandomizer {
  PuzzleRandomizer._();

  static const historyWindow = 8;
  static final Map<int, List<PuzzleShapeId>> _cache = {};

  static List<PuzzleShapeId> shapesFor(int id, PuzzleDifficulty spec) {
    final cached = _cache[id];
    if (cached != null) return cached;

    final rng = Random(id * 7919 + 17);
    final recentFamilies = <PuzzleFamily>{};
    final recentIds = <PuzzleShapeId>{};
    for (var i = 1; i <= historyWindow; i++) {
      if (id - i < 1) break;
      final prev = shapesFor(id - i, PuzzleDifficulty.of(id - i)).first;
      recentIds.add(prev);
      recentFamilies.add(prev.family);
    }

    var pool = spec.allowed
        .where((s) => !recentIds.contains(s) && !recentFamilies.contains(s.family))
        .toList();
    if (pool.length < spec.comboCount) {
      pool = spec.allowed.where((s) => !recentIds.contains(s)).toList();
    }
    if (pool.isEmpty) pool = List.of(spec.allowed);

    final picked = <PuzzleShapeId>[];
    for (var i = 0; i < spec.comboCount; i++) {
      var source = pool.where((s) => !picked.contains(s)).toList();
      final otherFamily = source
          .where((s) => picked.every((p) => p.family != s.family))
          .toList();
      if (otherFamily.isNotEmpty) source = otherFamily;
      if (source.isEmpty) source = List.of(spec.allowed);
      picked.add(source[rng.nextInt(source.length)]);
    }
    return _cache[id] = picked;
  }
}

/// Builds solvable snake-arrow levels from geometric shapes.
///
/// Each snake is inserted only when its exit ray is empty, so removing
/// snakes in reverse insertion order is always a valid solution.
class PuzzleGenerator {
  PuzzleGenerator._();

  static LevelDefinition generate(int id) {
    final spec = PuzzleDifficulty.of(id);

    LevelDefinition? best;
    var bestScore = double.infinity;

    for (var variant = 0; variant < 16; variant++) {
      final candidate = _buildCandidate(
        id: id,
        spec: spec,
        seed: id * 104729 + variant * 7919 + 31,
        // Odd variants let fill arrows' escape rays pass through shape cells:
        // shapes like rings then trap interior arrows until the ring leaves
        // ("one inside, one outside"). The validator rejects any variant
        // where that ordering doesn't work out.
        relaxed: variant.isOdd,
      );
      final check = PuzzleValidator.validate(candidate);
      if (!check.solvable) continue;

      final cells =
          candidate.snakes.fold<int>(0, (sum, s) => sum + s.cells.length);
      final fill = cells / (spec.rows * spec.cols);
      final snakeCount = candidate.snakes.length;
      final countPenalty = snakeCount < spec.minSnakes
          ? (spec.minSnakes - snakeCount) * 6.0
          : 0.0;
      final avgTurns = snakeCount == 0
          ? 0.0
          : candidate.snakes.fold<int>(0, (s, a) => s + _turnCount(a.cells)) /
              snakeCount;
      final mix = _mixScore(candidate.snakes.map((s) => s.cells).toList());
      final avgLen = snakeCount == 0 ? 0.0 : cells / snakeCount;
      final shortRatio = snakeCount == 0
          ? 0.0
          : candidate.snakes.where((s) => s.cells.length < 4).length /
              snakeCount;
      // Fill dominates: a sparse interlocking board must never beat a dense maze.
      final score = (1 - fill) * 320 +
          countPenalty +
          shortRatio * 8 +
          check.easeScore * 0.12 -
          avgTurns * 2.0 -
          avgLen * 0.5 -
          mix * 0.08;

      if (score < bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    var picked = best;
    if (picked == null) {
      for (var extra = 16; extra < 48; extra++) {
        final candidate = _buildCandidate(
          id: id,
          spec: spec,
          seed: id * 104729 + extra * 7919 + 31,
          relaxed: false,
        );
        if (PuzzleValidator.validate(candidate).solvable) {
          picked = candidate;
          break;
        }
      }
    }
    picked ??= _emergency(id, spec);

    final rng = Random(id * 31337 + 7);
    final hardened = _opposeNeighbors(_harden(picked, rng), rng);
    if (PuzzleValidator.validate(hardened).solvable) return hardened;
    return picked;
  }

  /// Flips free arrows so they point into other arrows (blocked at start),
  /// keeping each flip only if the level remains solvable. Cell occupancy is
  /// untouched, so only the flipped arrow's movability changes — the result
  /// is an opening position with just a few valid moves hidden among many.
  static LevelDefinition _harden(LevelDefinition level, Random rng) {
    final target = (level.snakes.length * 0.06).round().clamp(2, 6);
    final snakes = level.snakes.map((s) => List.of(s.cells)).toList();

    bool blockedAtStart(int index) {
      final body = snakes[index];
      final heading = _headingOf(body);
      if (heading == null) return true;
      final occupied = <Cell>{
        for (var i = 0; i < snakes.length; i++)
          if (i != index) ...snakes[i],
      };
      final (dr, dc) = heading.delta;
      var (r, c) = body.last;
      r += dr;
      c += dc;
      while (r >= 0 && r < level.rows && c >= 0 && c < level.cols) {
        if (occupied.contains((r, c))) return true;
        r += dr;
        c += dc;
      }
      return false;
    }

    LevelDefinition build() => LevelDefinition(
          id: level.id,
          rows: level.rows,
          cols: level.cols,
          snakes: snakes.map(LevelSnake.new).toList(),
          parMoves: level.parMoves,
          difficulty: level.difficulty,
          patternKey: level.patternKey,
        );

    var current = build();
    var open = PuzzleValidator.validate(current).initialMovable;

    // A flip rejected in one pass (it broke solvability) can succeed later
    // once other arrows have been flipped, so retry until no progress.
    for (var pass = 0; pass < 5 && open > target; pass++) {
      var improved = false;
      final order = List.generate(snakes.length, (i) => i)..shuffle(rng);
      for (final index in order) {
        if (open <= target) break;
        if (blockedAtStart(index)) continue;

        final original = snakes[index];
        snakes[index] = original.reversed.toList();
        if (!blockedAtStart(index)) {
          snakes[index] = original;
          continue;
        }

        final candidate = build();
        final check = PuzzleValidator.validate(candidate);
        if (!check.solvable) {
          snakes[index] = original;
          continue;
        }
        current = candidate;
        open = check.initialMovable;
        improved = true;
      }
      if (!improved) break;
    }

    return current;
  }

  /// Flip arrows so neighboring ones point opposite or perpendicular, not
  /// in a uniform flow. Occupancy is unchanged; only headings flip, and a
  /// flip is kept only when the level stays solvable.
  static LevelDefinition _opposeNeighbors(LevelDefinition level, Random rng) {
    final snakes = level.snakes.map((s) => List.of(s.cells)).toList();

    LevelDefinition build() => LevelDefinition(
          id: level.id,
          rows: level.rows,
          cols: level.cols,
          snakes: snakes.map(LevelSnake.new).toList(),
          parMoves: level.parMoves,
          difficulty: level.difficulty,
          patternKey: level.patternKey,
        );

    var current = build();
    var currentMix = _mixScore(snakes);
    var open = PuzzleValidator.validate(current).initialMovable;

    for (var pass = 0; pass < 4; pass++) {
      var improved = false;
      final order = List.generate(snakes.length, (i) => i)..shuffle(rng);
      for (final index in order) {
        final original = snakes[index];
        snakes[index] = original.reversed.toList();
        final newMix = _mixScore(snakes);
        if (newMix <= currentMix) {
          snakes[index] = original;
          continue;
        }
        final candidate = build();
        final check = PuzzleValidator.validate(candidate);
        if (!check.solvable || check.initialMovable > open + 1) {
          snakes[index] = original;
          continue;
        }
        current = candidate;
        currentMix = newMix;
        open = check.initialMovable;
        improved = true;
      }
      if (!improved) break;
    }
    return current;
  }

  static int _turnCount(List<Cell> body) {
    if (body.length < 3) return 0;
    var turns = 0;
    for (var i = 2; i < body.length; i++) {
      final d1r = body[i - 1].$1 - body[i - 2].$1;
      final d1c = body[i - 1].$2 - body[i - 2].$2;
      final d2r = body[i].$1 - body[i - 1].$1;
      final d2c = body[i].$2 - body[i - 1].$2;
      if (d1r != d2r || d1c != d2c) turns++;
    }
    return turns;
  }

  /// Higher is better: neighboring arrows point opposite or perpendicular,
  /// and the four cardinal headings are used evenly.
  static double _mixScore(List<List<Cell>> snakes) {
    final headings = <int, Direction>{};
    final owner = <Cell, int>{};
    for (var i = 0; i < snakes.length; i++) {
      final h = _headingOf(snakes[i]);
      if (h == null) continue;
      headings[i] = h;
      for (final cell in snakes[i]) {
        owner[cell] = i;
      }
    }

    var opposite = 0;
    var same = 0;
    var other = 0;
    const deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    for (var i = 0; i < snakes.length; i++) {
      final hi = headings[i];
      if (hi == null) continue;
      final seen = <int>{};
      for (final (r, c) in snakes[i]) {
        for (final (dr, dc) in deltas) {
          final n = owner[(r + dr, c + dc)];
          if (n == null || n == i || !seen.add(n)) continue;
          final hj = headings[n];
          if (hj == null) continue;
          if (hj == hi.opposite) {
            opposite++;
          } else if (hj == hi) {
            same++;
          } else {
            other++;
          }
        }
      }
    }

    final counts = <Direction, int>{
      for (final d in Direction.values) d: 0,
    };
    for (final h in headings.values) {
      counts[h] = counts[h]! + 1;
    }
    final total = max(1, headings.length);
    var entropy = 0.0;
    for (final n in counts.values) {
      if (n == 0) continue;
      final p = n / total;
      entropy -= p * log(p);
    }

    return opposite * 6 + other * 2 - same * 5 + entropy * 12;
  }

  static LevelDefinition _buildCandidate({
    required int id,
    required PuzzleDifficulty spec,
    required int seed,
    required bool relaxed,
  }) {
    final rng = Random(seed);
    final shapes = PuzzleRandomizer.shapesFor(id, spec);
    final occupied = <Cell>{};
    final placed = <List<Cell>>[];

    final regions = _regionsFor(spec, shapes.length, rng);
    for (var i = 0; i < shapes.length; i++) {
      final region = regions[i % regions.length];
      var paths = PuzzleShapeLibrary.build(shapes[i], region, rng);
      final turns = region.height == region.width
          ? rng.nextInt(4)
          : (rng.nextBool() ? 0 : 2);
      paths = PuzzleShapeLibrary.rotate(paths, region, turns);
      if (rng.nextBool()) {
        paths = PuzzleShapeLibrary.mirrorH(paths, region);
      }
      paths = _clipToBoard(paths, spec.rows, spec.cols);

      for (final path in paths) {
        final unique = [for (final c in path) if (!occupied.contains(c)) c];
        // Alternate heading along the shape so a U/V/loop is "one in, one
        // out" instead of a uniform flow.
        var flip = rng.nextBool();
        for (final body in _cutSnakes(
          unique,
          spec.minLen,
          spec.maxLen,
          rng,
        )) {
          final oriented = flip ? body.reversed.toList() : body;
          _commit(
            oriented,
            occupied,
            placed,
            spec.rows,
            spec.cols,
            rng: rng,
            preferGiven: true,
          );
          flip = !flip;
        }
      }
    }

    // In relaxed mode, later fill arrows may aim their escape rays through
    // the shape cells placed above — the shape leaves the board first and
    // frees them. Essential for enclosing shapes (rings, C/U) that would
    // otherwise wall off the interior and cap the arrow count.
    final rayIgnore = relaxed ? Set<Cell>.of(occupied) : const <Cell>{};

    _sprinkleExtras(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
      forceMinCount: true,
      maxCount: spec.packCap,
      rayIgnore: rayIgnore,
    );
    _fillFromEmpties(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
      maxCount: spec.packCap,
      rayIgnore: rayIgnore,
      packAll: true,
    );
    // Stack arrows onto open exit corridors. Strict rays only — occupying
    // another snake's ray while also aiming through it creates deadlocks.
    _addBlockers(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _fillFromEmpties(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
      maxCount: spec.packCap,
      rayIgnore: const {},
      packAll: true,
    );
    _packCrumbs(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _addBlockers(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _packCrumbs(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _packPairs(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _extendTails(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _boostFillIfSolvable(
      id: id,
      spec: spec,
      rng: rng,
      occupied: occupied,
      placed: placed,
    );

    if (placed.isEmpty) {
      placed.add([(spec.rows ~/ 2, 0), (spec.rows ~/ 2, 1)]);
    }

    return LevelDefinition(
      id: id,
      rows: spec.rows,
      cols: spec.cols,
      snakes: placed.map(LevelSnake.new).toList(),
      parMoves: placed.length,
      difficulty: spec.difficulty,
      patternKey: shapes.map((s) => s.name).join('+'),
    );
  }

  /// One more relaxed fill pass for leftover pockets, kept only if the
  /// board stays solvable. Recovers interior cells that strict rays skip.
  static void _boostFillIfSolvable({
    required int id,
    required PuzzleDifficulty spec,
    required Random rng,
    required Set<Cell> occupied,
    required List<List<Cell>> placed,
  }) {
    final cells = spec.rows * spec.cols;
    if (cells == 0) return;
    if (occupied.length / cells >= spec.fill &&
        placed.length >= spec.minSnakes) {
      return;
    }

    final savedPlaced = placed.map((s) => List<Cell>.of(s)).toList();
    final savedOcc = Set<Cell>.of(occupied);

    _fillFromEmpties(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
      maxCount: spec.packCap,
      rayIgnore: Set<Cell>.of(occupied),
      packAll: true,
    );
    _addBlockers(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _packCrumbs(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _packPairs(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _extendTails(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );

    final boosted = LevelDefinition(
      id: id,
      rows: spec.rows,
      cols: spec.cols,
      snakes: placed.map(LevelSnake.new).toList(),
      parMoves: placed.length,
      difficulty: spec.difficulty,
      patternKey: 'boost',
    );
    if (PuzzleValidator.validate(boosted).solvable) return;

    placed
      ..clear()
      ..addAll(savedPlaced);
    occupied
      ..clear()
      ..addAll(savedOcc);
  }

  static List<GridRegion> _regionsFor(
    PuzzleDifficulty spec,
    int count,
    Random rng,
  ) {
    final board = GridRegion(
      spec.inset,
      spec.inset,
      spec.rows - 1 - spec.inset,
      spec.cols - 1 - spec.inset,
    );

    if (count <= 1) return [board];

    if (count == 2) {
      if (rng.nextBool() && board.width >= 5) {
        final mid = board.c0 + board.width ~/ 2;
        return [
          GridRegion(board.r0, board.c0, board.r1, mid),
          GridRegion(board.r0, mid, board.r1, board.c1),
        ];
      }
      if (board.height >= 5) {
        final mid = board.r0 + board.height ~/ 2;
        return [
          GridRegion(board.r0, board.c0, mid, board.c1),
          GridRegion(mid, board.c0, board.r1, board.c1),
        ];
      }
    }

    if (count >= 3 && board.height >= 6 && board.width >= 6) {
      final rm = board.cr;
      final cm = board.cc;
      return [
        GridRegion(board.r0, board.c0, rm, cm),
        GridRegion(board.r0, cm, rm, board.c1),
        GridRegion(rm, board.c0, board.r1, board.c1),
      ];
    }

    return [board, board];
  }

  static List<List<Cell>> _clipToBoard(
    List<List<Cell>> paths,
    int rows,
    int cols,
  ) {
    final out = <List<Cell>>[];
    for (final path in paths) {
      final clipped = [
        for (final (r, c) in path)
          if (r >= 0 && r < rows && c >= 0 && c < cols) (r, c),
      ];
      if (clipped.length >= 2) out.add(clipped);
    }
    return out;
  }

  static List<List<Cell>> _cutSnakes(
    List<Cell> path,
    int minLen,
    int maxLen,
    Random rng,
  ) {
    final runs = <List<Cell>>[];
    var current = <Cell>[];
    for (final cell in path) {
      if (current.isEmpty) {
        current.add(cell);
        continue;
      }
      final prev = current.last;
      final dist = (prev.$1 - cell.$1).abs() + (prev.$2 - cell.$2).abs();
      if (dist == 1) {
        current.add(cell);
      } else {
        if (current.length >= 2) runs.add(current);
        current = [cell];
      }
    }
    if (current.length >= 2) runs.add(current);

    final snakes = <List<Cell>>[];
    for (final run in runs) {
      var i = 0;
      while (i < run.length - 1) {
        final remaining = run.length - i;
        var len = minLen + rng.nextInt(max(1, min(maxLen, remaining) - minLen + 1));
        if (rng.nextDouble() < 0.32) {
          len = min(maxLen, remaining);
        }
        len = len.clamp(2, remaining);
        len = _preferTurnLength(run, i, len, minLen, min(maxLen, remaining));
        if (remaining - len == 1) len = remaining;
        snakes.add(run.sublist(i, i + len));
        i += len;
      }
    }
    return snakes;
  }

  static int _preferTurnLength(
    List<Cell> run,
    int start,
    int len,
    int minLen,
    int maxLen,
  ) {
    bool hasTurn(int l) {
      if (start + l > run.length || l < 3) return false;
      return _turnCount(run.sublist(start, start + l)) > 0;
    }

    if (hasTurn(len)) return len;
    for (var l = maxLen; l >= minLen; l--) {
      if (start + l <= run.length && hasTurn(l)) return l;
    }
    return len;
  }

  static bool _commit(
    List<Cell> body,
    Set<Cell> occupied,
    List<List<Cell>> placed,
    int rows,
    int cols, {
    Random? rng,
    Set<Cell> rayIgnore = const {},
    bool preferGiven = false,
  }) {
    final forwardOk = _canInsert(body, occupied, rows, cols, rayIgnore);
    final reversed = body.reversed.toList();
    final reverseOk = _canInsert(reversed, occupied, rows, cols, rayIgnore);

    List<Cell>? chosen;
    if (forwardOk && reverseOk) {
      final fwdScore = _orientationScore(body, placed, rows, cols) +
          (preferGiven ? 3.0 : 0);
      final revScore = _orientationScore(reversed, placed, rows, cols);
      final preferBest = rng == null || rng.nextDouble() < 0.9;
      if (preferBest) {
        chosen = fwdScore >= revScore ? body : reversed;
      } else {
        chosen = fwdScore >= revScore ? reversed : body;
      }
    } else if (forwardOk) {
      chosen = body;
    } else if (reverseOk) {
      chosen = reversed;
    }

    if (chosen == null) return false;
    // Relaxed fill may aim through earlier snakes, but sitting on those
    // snakes' open exit rays at the same time is a two-cycle deadlock.
    if (rayIgnore.isNotEmpty &&
        _occupiesOpenRay(chosen, placed, rows, cols, occupied)) {
      return false;
    }
    occupied.addAll(chosen);
    placed.add(chosen);
    return true;
  }

  static bool _occupiesOpenRay(
    List<Cell> body,
    List<List<Cell>> placed,
    int rows,
    int cols,
    Set<Cell> occupied,
  ) {
    final bodySet = body.toSet();
    for (final other in placed) {
      final ray = _exitRayCells(other, rows, cols, occupied);
      if (ray == null) continue;
      for (final cell in ray) {
        if (bodySet.contains(cell)) return true;
      }
    }
    return false;
  }

  static double _orientationScore(
    List<Cell> body,
    List<List<Cell>> placed,
    int rows,
    int cols,
  ) {
    final heading = _headingOf(body);
    if (heading == null) return -999;
    final (opposite, same, other) = _neighborDirs(body, heading, placed);
    final counts = <Direction, int>{};
    for (final placedBody in placed) {
      final h = _headingOf(placedBody);
      if (h != null) counts[h] = (counts[h] ?? 0) + 1;
    }
    return opposite * 5 +
        other * 1.5 -
        same * 4 -
        (counts[heading] ?? 0) * 0.6 +
        _distanceToEdge(body, rows, cols) * 0.12 +
        _turnCount(body) * 0.8;
  }

  static (int opposite, int same, int other) _neighborDirs(
    List<Cell> body,
    Direction heading,
    List<List<Cell>> placed,
  ) {
    final owner = <Cell, int>{};
    for (var i = 0; i < placed.length; i++) {
      for (final cell in placed[i]) {
        owner[cell] = i;
      }
    }
    final bodySet = body.toSet();
    final seen = <int>{};
    var opposite = 0;
    var same = 0;
    var other = 0;
    const deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    for (final (r, c) in body) {
      for (final (dr, dc) in deltas) {
        final n = (r + dr, c + dc);
        if (bodySet.contains(n)) continue;
        final idx = owner[n];
        if (idx == null || !seen.add(idx)) continue;
        final nh = _headingOf(placed[idx]);
        if (nh == null) continue;
        if (nh == heading.opposite) {
          opposite++;
        } else if (nh == heading) {
          same++;
        } else {
          other++;
        }
      }
    }
    return (opposite, same, other);
  }

  static int _distanceToEdge(List<Cell> body, int rows, int cols) {
    final heading = _headingOf(body);
    if (heading == null) return 0;
    final (r, c) = body.last;
    return switch (heading) {
      Direction.up => r,
      Direction.down => rows - 1 - r,
      Direction.left => c,
      Direction.right => cols - 1 - c,
    };
  }

  static bool _canInsert(
    List<Cell> body,
    Set<Cell> occupied,
    int rows,
    int cols, [
    Set<Cell> rayIgnore = const {},
  ]) {
    if (body.length < 2) return false;
    if (body.toSet().length != body.length) return false;
    for (final cell in body) {
      final (r, c) = cell;
      if (r < 0 || r >= rows || c < 0 || c >= cols) return false;
      if (occupied.contains(cell)) return false;
    }
    for (var i = 1; i < body.length; i++) {
      final a = body[i - 1];
      final b = body[i];
      if ((a.$1 - b.$1).abs() + (a.$2 - b.$2).abs() != 1) return false;
    }

    final heading = _headingOf(body);
    if (heading == null) return false;
    final (dr, dc) = heading.delta;
    var (r, c) = body.last;
    r += dr;
    c += dc;
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      if (occupied.contains((r, c)) && !rayIgnore.contains((r, c))) {
        return false;
      }
      r += dr;
      c += dc;
    }
    return true;
  }

  /// Cells of a snake's escape ray if it is currently clear, else null.
  static List<Cell>? _exitRayCells(
    List<Cell> body,
    int rows,
    int cols,
    Set<Cell> occupied,
  ) {
    final heading = _headingOf(body);
    if (heading == null) return null;
    final (dr, dc) = heading.delta;
    var (r, c) = body.last;
    r += dr;
    c += dc;
    final ray = <Cell>[];
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      if (occupied.contains((r, c))) return null;
      ray.add((r, c));
      r += dr;
      c += dc;
    }
    return ray;
  }

  /// Deliberately parks new arrows across other arrows' escape paths.
  ///
  /// Prefers stacking a same-heading arrow closer to the edge (fills the
  /// empty corridor the blocked arrow needs) then tries perpendicular
  /// crossings. Each blocker is inserted with a strict clear exit, so
  /// solvability is preserved.
  static void _addBlockers({
    required Random rng,
    required PuzzleDifficulty spec,
    required Set<Cell> occupied,
    required List<List<Cell>> placed,
  }) {
    final cap = spec.packCap;
    for (var round = 0; round < spec.blockDepth; round++) {
      if (placed.length >= cap) return;

      var added = false;
      final snapshot = List<List<Cell>>.of(placed);
      snapshot.shuffle(rng);
      for (final body in snapshot) {
        if (placed.length >= cap) break;
        final heading = _headingOf(body);
        if (heading == null) continue;
        final ray = _exitRayCells(body, spec.rows, spec.cols, occupied);
        if (ray == null || ray.isEmpty) continue;

        final attempts = <(Cell, Direction)>[];
        // Same heading, starting further from the original head so the
        // walk can grow back along the corridor.
        for (var i = ray.length - 1; i >= 1; i--) {
          attempts.add((ray[i], heading));
        }
        final side = List.of(Direction.values)
          ..remove(heading)
          ..remove(heading.opposite)
          ..shuffle(rng);
        final cross = <(Cell, Direction)>[];
        for (final cell in ray) {
          for (final dir in side) {
            cross.add((cell, dir));
          }
        }
        cross.shuffle(rng);
        attempts.addAll(cross);
        attempts.add((ray.first, heading));

        for (final (head, dir) in attempts) {
          if (occupied.contains(head)) continue;
          final walked = _walkFromHead(
            rng: rng,
            spec: spec,
            occupied: occupied,
            head: head,
            heading: dir,
            minOverride: 3,
            maxOverride: spec.maxLen,
          );
          if (walked == null) continue;
          if (_commit(walked, occupied, placed, spec.rows, spec.cols,
              rng: rng)) {
            added = true;
            break;
          }
        }
      }
      if (!added) return;
    }
  }

  static Direction? _headingOf(List<Cell> body) {
    final (hr, hc) = body.last;
    final (pr, pc) = body[body.length - 2];
    if (hr == pr && hc == pc) return null;
    if (hr < pr) return Direction.up;
    if (hr > pr) return Direction.down;
    if (hc < pc) return Direction.left;
    if (hc > pc) return Direction.right;
    return null;
  }

  static void _sprinkleExtras({
    required Random rng,
    required PuzzleDifficulty spec,
    required Set<Cell> occupied,
    required List<List<Cell>> placed,
    required bool forceMinCount,
    int? maxCount,
    Set<Cell> rayIgnore = const {},
  }) {
    final cap = maxCount ?? spec.packCap;
    final targetCells = (spec.rows * spec.cols * spec.fill).round();
    var attempts = spec.rows * spec.cols * 30;

    while (attempts-- > 0 && placed.length < cap) {
      final needCount = placed.length < spec.minSnakes;
      final needFill = occupied.length < targetCells;
      if (!needCount && !needFill && !forceMinCount) break;
      if (!needCount && !needFill && spec.decoyChance <= 0) break;
      if (!needCount && rng.nextDouble() > spec.decoyChance + 0.4) continue;

      final body = _walkSnake(
        rng: rng,
        spec: spec,
        occupied: occupied,
        rayIgnore: rayIgnore,
      );
      if (body == null) continue;
      _commit(body, occupied, placed, spec.rows, spec.cols,
          rng: rng, rayIgnore: rayIgnore);
    }
  }

  static void _fillFromEmpties({
    required Random rng,
    required PuzzleDifficulty spec,
    required Set<Cell> occupied,
    required List<List<Cell>> placed,
    int? maxCount,
    Set<Cell> rayIgnore = const {},
    bool packAll = false,
  }) {
    final cap = maxCount ?? spec.packCap;
    final targetCells = (spec.rows * spec.cols * spec.fill).round();
    var changed = true;
    var guard = 0;
    while (changed && guard++ < 36) {
      changed = false;
      if (placed.length >= cap) break;
      if (!packAll &&
          placed.length >= spec.minSnakes &&
          occupied.length >= targetCells) {
        break;
      }

      final empties = <Cell>[
        for (var r = 0; r < spec.rows; r++)
          for (var c = 0; c < spec.cols; c++)
            if (!occupied.contains((r, c))) (r, c),
      ]..shuffle(rng);

      for (final head in empties) {
        if (occupied.contains(head)) continue;
        if (placed.length >= cap) break;
        if (!packAll &&
            placed.length >= spec.minSnakes &&
            occupied.length >= targetCells) {
          break;
        }
        final directions = List.of(Direction.values)..shuffle(rng);
        var placedHere = false;
        for (final minTry in [spec.minLen, 4, 3]) {
          if (placedHere) break;
          for (final heading in directions) {
            final body = _walkFromHead(
              rng: rng,
              spec: spec,
              occupied: occupied,
              head: head,
              heading: heading,
              rayIgnore: rayIgnore,
              minOverride: minTry,
              maxOverride: spec.maxLen,
            );
            if (body == null) continue;
            if (_commit(body, occupied, placed, spec.rows, spec.cols,
                rng: rng, rayIgnore: rayIgnore)) {
              changed = true;
              placedHere = true;
              break;
            }
          }
        }
      }
    }
  }

  /// Fill leftover 3–4 cell pockets so the maze has no large holes.
  static void _packCrumbs({
    required Random rng,
    required PuzzleDifficulty spec,
    required Set<Cell> occupied,
    required List<List<Cell>> placed,
  }) {
    if (placed.length >= spec.packCap) return;
    var changed = true;
    var guard = 0;
    while (changed && guard++ < 20 && placed.length < spec.packCap) {
      changed = false;
      final empties = <Cell>[
        for (var r = 0; r < spec.rows; r++)
          for (var c = 0; c < spec.cols; c++)
            if (!occupied.contains((r, c))) (r, c),
      ]..shuffle(rng);
      for (final head in empties) {
        if (occupied.contains(head) || placed.length >= spec.packCap) break;
        final directions = List.of(Direction.values)..shuffle(rng);
        for (final heading in directions) {
          final body = _walkFromHead(
            rng: rng,
            spec: spec,
            occupied: occupied,
            head: head,
            heading: heading,
            minOverride: 3,
            maxOverride: max(5, spec.minLen),
          );
          if (body == null || body.length < 3) continue;
          if (_commit(body, occupied, placed, spec.rows, spec.cols,
              rng: rng)) {
            changed = true;
            break;
          }
        }
      }
    }
  }

  /// Last-resort 2-cell arrows for leftover adjacent empties.
  static void _packPairs({
    required Random rng,
    required PuzzleDifficulty spec,
    required Set<Cell> occupied,
    required List<List<Cell>> placed,
  }) {
    if (placed.length >= spec.packCap) return;
    var changed = true;
    var guard = 0;
    while (changed && guard++ < 12 && placed.length < spec.packCap) {
      changed = false;
      final empties = <Cell>[
        for (var r = 0; r < spec.rows; r++)
          for (var c = 0; c < spec.cols; c++)
            if (!occupied.contains((r, c))) (r, c),
      ]..shuffle(rng);
      for (final head in empties) {
        if (occupied.contains(head) || placed.length >= spec.packCap) break;
        final directions = List.of(Direction.values)..shuffle(rng);
        for (final heading in directions) {
          final (dr, dc) = heading.delta;
          final tail = (head.$1 - dr, head.$2 - dc);
          final body = [tail, head];
          if (_commit(body, occupied, placed, spec.rows, spec.cols,
              rng: rng)) {
            changed = true;
            break;
          }
        }
      }
    }
  }

  /// Grow existing arrows into leftover holes that are not serving as
  /// anyone's exit corridor. Occupancy of open rays is left for blockers.
  static void _extendTails({
    required Random rng,
    required PuzzleDifficulty spec,
    required Set<Cell> occupied,
    required List<List<Cell>> placed,
  }) {
    var changed = true;
    var guard = 0;
    while (changed && guard++ < 24) {
      changed = false;
      final reserved = <Cell>{};
      for (final body in placed) {
        final ray = _exitRayCells(body, spec.rows, spec.cols, occupied);
        if (ray != null) reserved.addAll(ray);
      }
      final order = List.generate(placed.length, (i) => i)..shuffle(rng);
      for (final i in order) {
        final body = placed[i];
        final tail = body.first;
        final dirs = List.of(Direction.values)..shuffle(rng);
        for (final dir in dirs) {
          final (dr, dc) = dir.delta;
          final next = (tail.$1 + dr, tail.$2 + dc);
          final (r, c) = next;
          if (r < 0 || r >= spec.rows || c < 0 || c >= spec.cols) continue;
          if (occupied.contains(next) || reserved.contains(next)) continue;
          if (body.contains(next)) continue;
          body.insert(0, next);
          occupied.add(next);
          changed = true;
          break;
        }
      }
    }
  }

  static List<Cell>? _walkSnake({
    required Random rng,
    required PuzzleDifficulty spec,
    required Set<Cell> occupied,
    Set<Cell> rayIgnore = const {},
  }) {
    return _walkFromHead(
      rng: rng,
      spec: spec,
      occupied: occupied,
      head: (rng.nextInt(spec.rows), rng.nextInt(spec.cols)),
      heading: Direction.values[rng.nextInt(4)],
      rayIgnore: rayIgnore,
    );
  }

  static List<Cell>? _walkFromHead({
    required Random rng,
    required PuzzleDifficulty spec,
    required Set<Cell> occupied,
    required Cell head,
    required Direction heading,
    Set<Cell> rayIgnore = const {},
    int? minOverride,
    int? maxOverride,
  }) {
    if (occupied.contains(head)) return null;
    final (dr, dc) = heading.delta;

    final ray = <Cell>{};
    var (r, c) = head;
    r += dr;
    c += dc;
    while (r >= 0 && r < spec.rows && c >= 0 && c < spec.cols) {
      if (occupied.contains((r, c)) && !rayIgnore.contains((r, c))) {
        return null;
      }
      ray.add((r, c));
      r += dr;
      c += dc;
    }

    final body = <Cell>[head];
    final first = (head.$1 - dr, head.$2 - dc);
    if (!_isFree(first, spec.rows, spec.cols, occupied, ray, body)) {
      return null;
    }
    body.add(first);

    final minLen = minOverride ?? spec.minLen;
    final maxLen = maxOverride ?? spec.maxLen;
    var target = minLen + rng.nextInt(max(1, maxLen - minLen + 1));
    if (rng.nextDouble() < 0.24) {
      target = maxLen;
    }
    var current = first;
    var lastStep = (first.$1 - head.$1, first.$2 - head.$2);
    var straightRun = 1;
    var turnsMade = 0;

    while (body.length < target) {
      final straight = <Cell>[];
      final turns = <Cell>[];
      for (final dir in Direction.values) {
        final (sr, sc) = dir.delta;
        final next = (current.$1 + sr, current.$2 + sc);
        if (!_isFree(next, spec.rows, spec.cols, occupied, ray, body)) continue;
        if ((sr, sc) == lastStep) {
          straight.add(next);
        } else {
          turns.add(next);
        }
      }
      if (straight.isEmpty && turns.isEmpty) break;

      // Corridors stay long; U / L bends appear often enough to nest paths.
      final mustTurn = straightRun >= 4 && turns.isNotEmpty;
      final wantU =
          turnsMade >= 1 && turns.isNotEmpty && rng.nextDouble() < 0.48;
      final wantTurn = turns.isNotEmpty &&
          (mustTurn || wantU || rng.nextDouble() < spec.turnBias);
      final pool = wantTurn
          ? turns
          : (straight.isNotEmpty ? straight : turns);
      final next = pool[rng.nextInt(pool.length)];
      final step = (next.$1 - current.$1, next.$2 - current.$2);
      if (step == lastStep) {
        straightRun++;
      } else {
        straightRun = 1;
        turnsMade++;
      }
      lastStep = step;
      current = next;
      body.add(next);
    }

    if (body.length < minLen) return null;
    return body.reversed.toList();
  }

  static bool _isFree(
    Cell cell,
    int rows,
    int cols,
    Set<Cell> occupied,
    Set<Cell> ray,
    List<Cell> body,
  ) {
    final (r, c) = cell;
    if (r < 0 || r >= rows || c < 0 || c >= cols) return false;
    if (occupied.contains(cell) || ray.contains(cell) || body.contains(cell)) {
      return false;
    }
    return true;
  }

  static LevelDefinition _emergency(int id, PuzzleDifficulty spec) {
    final occupied = <Cell>{};
    final placed = <List<Cell>>[];
    final rng = Random(id * 13);
    _sprinkleExtras(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
      forceMinCount: true,
      maxCount: spec.packCap,
    );
    _fillFromEmpties(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
      maxCount: spec.packCap,
      packAll: true,
    );
    _addBlockers(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _packCrumbs(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _packPairs(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    _extendTails(
      rng: rng,
      spec: spec,
      occupied: occupied,
      placed: placed,
    );
    if (placed.isEmpty || !PuzzleValidator.validate(LevelDefinition(
          id: id,
          rows: spec.rows,
          cols: spec.cols,
          snakes: placed.map(LevelSnake.new).toList(),
          parMoves: placed.length,
          difficulty: spec.difficulty,
          patternKey: 'fallback',
        )).solvable) {
      placed.clear();
      occupied.clear();
      // Brick rows of 4–6 cell arrows, alternating heading so the board
      // stays dense and mixed if regular generation produced nothing valid.
      for (var r = 0; r < spec.rows; r++) {
        var c = 0;
        var faceRight = r.isEven;
        while (c + 1 < spec.cols) {
          final len = min(4 + (r + c) % 3, spec.cols - c);
          if (len < 2) break;
          final cells = [for (var i = 0; i < len; i++) (r, c + i)];
          placed.add(faceRight ? cells : cells.reversed.toList());
          occupied.addAll(cells);
          c += len;
          faceRight = !faceRight;
        }
      }
    }
    if (placed.isEmpty) {
      placed.add([(0, 0), (0, 1), (0, 2)]);
    }
    return LevelDefinition(
      id: id,
      rows: spec.rows,
      cols: spec.cols,
      snakes: placed.map(LevelSnake.new).toList(),
      parMoves: placed.length,
      difficulty: spec.difficulty,
      patternKey: 'fallback',
    );
  }
}
