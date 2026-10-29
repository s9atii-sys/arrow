import 'dart:math';

import '../models/level.dart';

/// Geometric structures the arrow bars themselves form on the board.
enum PuzzleShapeId {
  straightH,
  straightV,
  lShape,
  reverseL,
  uShape,
  invertedU,
  cShape,
  sShape,
  zShape,
  wShape,
  mShape,
  vShape,
  reverseV,
  square,
  rectangle,
  roundedRect,
  doubleRect,
  nestedRect,
  diamond,
  doubleDiamond,
  triangle,
  invertedTriangle,
  plus,
  cross,
  tShape,
  hShape,
  xShape,
  star,
  spiral,
  reverseSpiral,
  snake,
  zigzag,
  staircase,
  wave,
  ring,
  doubleRing,
  brokenCircle,
  semiCircle,
  clock,
  flower,
  pinwheel,
  maze,
  infinity,
  arrowhead,
  bowtie,
  crown,
  lightning,
}

enum PuzzleFamily {
  linear,
  elbow,
  uFamily,
  zigzag,
  rect,
  diamond,
  cross,
  loop,
  maze,
}

extension PuzzleShapeIdX on PuzzleShapeId {
  PuzzleFamily get family => switch (this) {
        PuzzleShapeId.straightH || PuzzleShapeId.straightV => PuzzleFamily.linear,
        PuzzleShapeId.lShape ||
        PuzzleShapeId.reverseL ||
        PuzzleShapeId.tShape ||
        PuzzleShapeId.arrowhead =>
          PuzzleFamily.elbow,
        PuzzleShapeId.uShape ||
        PuzzleShapeId.invertedU ||
        PuzzleShapeId.cShape ||
        PuzzleShapeId.crown =>
          PuzzleFamily.uFamily,
        PuzzleShapeId.sShape ||
        PuzzleShapeId.zShape ||
        PuzzleShapeId.wShape ||
        PuzzleShapeId.mShape ||
        PuzzleShapeId.zigzag ||
        PuzzleShapeId.wave ||
        PuzzleShapeId.lightning ||
        PuzzleShapeId.staircase ||
        PuzzleShapeId.snake =>
          PuzzleFamily.zigzag,
        PuzzleShapeId.square ||
        PuzzleShapeId.rectangle ||
        PuzzleShapeId.roundedRect ||
        PuzzleShapeId.doubleRect ||
        PuzzleShapeId.nestedRect =>
          PuzzleFamily.rect,
        PuzzleShapeId.diamond ||
        PuzzleShapeId.doubleDiamond ||
        PuzzleShapeId.vShape ||
        PuzzleShapeId.reverseV ||
        PuzzleShapeId.triangle ||
        PuzzleShapeId.invertedTriangle ||
        PuzzleShapeId.bowtie =>
          PuzzleFamily.diamond,
        PuzzleShapeId.plus ||
        PuzzleShapeId.cross ||
        PuzzleShapeId.hShape ||
        PuzzleShapeId.xShape ||
        PuzzleShapeId.star =>
          PuzzleFamily.cross,
        PuzzleShapeId.spiral ||
        PuzzleShapeId.reverseSpiral ||
        PuzzleShapeId.ring ||
        PuzzleShapeId.doubleRing ||
        PuzzleShapeId.brokenCircle ||
        PuzzleShapeId.semiCircle ||
        PuzzleShapeId.clock ||
        PuzzleShapeId.flower ||
        PuzzleShapeId.pinwheel ||
        PuzzleShapeId.infinity =>
          PuzzleFamily.loop,
        PuzzleShapeId.maze => PuzzleFamily.maze,
      };
}

class PuzzleShapeCatalog {
  PuzzleShapeCatalog._();

  static const intro = [
    PuzzleShapeId.uShape,
    PuzzleShapeId.invertedU,
    PuzzleShapeId.vShape,
    PuzzleShapeId.reverseV,
    PuzzleShapeId.lShape,
    PuzzleShapeId.reverseL,
    PuzzleShapeId.cShape,
    PuzzleShapeId.zigzag,
    PuzzleShapeId.star,
    PuzzleShapeId.staircase,
  ];

  static const early = [
    PuzzleShapeId.lShape,
    PuzzleShapeId.reverseL,
    PuzzleShapeId.uShape,
    PuzzleShapeId.invertedU,
    PuzzleShapeId.cShape,
    PuzzleShapeId.rectangle,
    PuzzleShapeId.tShape,
    PuzzleShapeId.staircase,
    PuzzleShapeId.zShape,
  ];

  static const mid = [
    PuzzleShapeId.square,
    PuzzleShapeId.rectangle,
    PuzzleShapeId.nestedRect,
    PuzzleShapeId.diamond,
    PuzzleShapeId.plus,
    PuzzleShapeId.sShape,
    PuzzleShapeId.zShape,
    PuzzleShapeId.zigzag,
    PuzzleShapeId.wave,
    PuzzleShapeId.ring,
    PuzzleShapeId.hShape,
    PuzzleShapeId.triangle,
    PuzzleShapeId.lightning,
  ];

  static const tricky = [
    PuzzleShapeId.spiral,
    PuzzleShapeId.reverseSpiral,
    PuzzleShapeId.plus,
    PuzzleShapeId.cross,
    PuzzleShapeId.diamond,
    PuzzleShapeId.doubleDiamond,
    PuzzleShapeId.pinwheel,
    PuzzleShapeId.infinity,
    PuzzleShapeId.flower,
    PuzzleShapeId.clock,
    PuzzleShapeId.xShape,
    PuzzleShapeId.star,
    PuzzleShapeId.bowtie,
    PuzzleShapeId.doubleRect,
    PuzzleShapeId.nestedRect,
    PuzzleShapeId.semiCircle,
  ];

  static const hard = [
    PuzzleShapeId.spiral,
    PuzzleShapeId.nestedRect,
    PuzzleShapeId.doubleRing,
    PuzzleShapeId.pinwheel,
    PuzzleShapeId.maze,
    PuzzleShapeId.infinity,
    PuzzleShapeId.star,
    PuzzleShapeId.flower,
    PuzzleShapeId.cross,
    PuzzleShapeId.doubleDiamond,
    PuzzleShapeId.clock,
    PuzzleShapeId.lightning,
    PuzzleShapeId.crown,
    PuzzleShapeId.arrowhead,
    PuzzleShapeId.wShape,
    PuzzleShapeId.mShape,
    PuzzleShapeId.brokenCircle,
  ];

  static const expert = PuzzleShapeId.values;
}

/// Inclusive rectangle on the grid used to stamp a shape.
class GridRegion {
  const GridRegion(this.r0, this.c0, this.r1, this.c1);

  final int r0;
  final int c0;
  final int r1;
  final int c1;

  int get height => r1 - r0 + 1;
  int get width => c1 - c0 + 1;
  int get cr => (r0 + r1) ~/ 2;
  int get cc => (c0 + c1) ~/ 2;

  bool contains(Cell cell) {
    final (r, c) = cell;
    return r >= r0 && r <= r1 && c >= c0 && c <= c1;
  }
}

/// Builds 4-connected polylines that arrow snakes later occupy.
class PuzzleShapeLibrary {
  PuzzleShapeLibrary._();

  static List<List<Cell>> build(
    PuzzleShapeId id,
    GridRegion g,
    Random rng,
  ) {
    if (g.height < 2 || g.width < 2) return const [];

    final raw = switch (id) {
      PuzzleShapeId.straightH => _straightH(g),
      PuzzleShapeId.straightV => _straightV(g),
      PuzzleShapeId.lShape => _l(g, reverse: false),
      PuzzleShapeId.reverseL => _l(g, reverse: true),
      PuzzleShapeId.uShape => _u(g, invert: false),
      PuzzleShapeId.invertedU => _u(g, invert: true),
      PuzzleShapeId.cShape => _c(g),
      PuzzleShapeId.sShape => _s(g),
      PuzzleShapeId.zShape => _z(g),
      PuzzleShapeId.wShape => _w(g),
      PuzzleShapeId.mShape => _m(g),
      PuzzleShapeId.vShape => _vLetter(g, invert: false),
      PuzzleShapeId.reverseV => _vLetter(g, invert: true),
      PuzzleShapeId.square => _rect(g, square: true),
      PuzzleShapeId.rectangle => _rect(g, square: false),
      PuzzleShapeId.roundedRect => _roundedRect(g),
      PuzzleShapeId.doubleRect => _doubleRect(g),
      PuzzleShapeId.nestedRect => _nestedRect(g),
      PuzzleShapeId.diamond => _diamond(g, rings: 1),
      PuzzleShapeId.doubleDiamond => _diamond(g, rings: 2),
      PuzzleShapeId.triangle => _triangle(g, invert: false),
      PuzzleShapeId.invertedTriangle => _triangle(g, invert: true),
      PuzzleShapeId.plus => _plus(g),
      PuzzleShapeId.cross => _plus(g),
      PuzzleShapeId.tShape => _t(g),
      PuzzleShapeId.hShape => _hLetter(g),
      PuzzleShapeId.xShape => _x(g),
      PuzzleShapeId.star => _star(g),
      PuzzleShapeId.spiral => _spiral(g, reverse: false),
      PuzzleShapeId.reverseSpiral => _spiral(g, reverse: true),
      PuzzleShapeId.snake => _snake(g),
      PuzzleShapeId.zigzag => _zigzag(g),
      PuzzleShapeId.staircase => _staircase(g),
      PuzzleShapeId.wave => _wave(g),
      PuzzleShapeId.ring => _ring(g),
      PuzzleShapeId.doubleRing => _doubleRing(g),
      PuzzleShapeId.brokenCircle => _brokenCircle(g),
      PuzzleShapeId.semiCircle => _semiCircle(g),
      PuzzleShapeId.clock => _clock(g),
      PuzzleShapeId.flower => _flower(g),
      PuzzleShapeId.pinwheel => _pinwheel(g),
      PuzzleShapeId.maze => _maze(g, rng),
      PuzzleShapeId.infinity => _infinity(g),
      PuzzleShapeId.arrowhead => _arrowhead(g),
      PuzzleShapeId.bowtie => _bowtie(g),
      PuzzleShapeId.crown => _crown(g),
      PuzzleShapeId.lightning => _lightning(g),
    };

    return _sanitize(raw, g);
  }

  static List<List<Cell>> rotate(List<List<Cell>> paths, GridRegion g, int turns) {
    var out = paths;
    final t = turns % 4;
    for (var i = 0; i < t; i++) {
      out = [
        for (final path in out)
          [
            for (final (r, c) in path)
              (g.r0 + (c - g.c0), g.c1 - (r - g.r0)),
          ],
      ];
    }
    return out;
  }

  static List<List<Cell>> mirrorH(List<List<Cell>> paths, GridRegion g) {
    return [
      for (final path in paths)
        [for (final (r, c) in path) (r, g.c0 + g.c1 - c)],
    ];
  }

  // --- primitives ---

  static List<Cell> _hLine(int r, int c0, int c1) {
    if (c0 == c1) return [(r, c0)];
    final step = c1 >= c0 ? 1 : -1;
    return [for (var c = c0; c != c1 + step; c += step) (r, c)];
  }

  static List<Cell> _vLine(int r0, int r1, int c) {
    if (r0 == r1) return [(r0, c)];
    final step = r1 >= r0 ? 1 : -1;
    return [for (var r = r0; r != r1 + step; r += step) (r, c)];
  }

  static List<Cell> _join(List<List<Cell>> parts) {
    if (parts.isEmpty) return const [];
    final out = <Cell>[parts.first.first];
    for (final part in parts) {
      for (final cell in part) {
        if (out.last != cell) out.add(cell);
      }
    }
    return out;
  }

  static List<Cell> _perimeter(GridRegion g, {bool open = false}) {
    final top = _hLine(g.r0, g.c0, g.c1);
    final right = _vLine(g.r0, g.r1, g.c1);
    final bottom = _hLine(g.r1, g.c1, g.c0);
    final left = _vLine(g.r1, g.r0, g.c0);
    final loop = _join([top, right, bottom, left]);
    if (open && loop.length > 1) return loop.sublist(0, loop.length - 1);
    return loop;
  }

  // --- shapes ---

  static List<List<Cell>> _straightH(GridRegion g) {
    final r = g.cr;
    return [_hLine(r, g.c0, g.c1)];
  }

  static List<List<Cell>> _straightV(GridRegion g) {
    final c = g.cc;
    return [_vLine(g.r0, g.r1, c)];
  }

  static List<List<Cell>> _l(GridRegion g, {required bool reverse}) {
    if (reverse) {
      return [
        _join([
          _hLine(g.r0, g.c1, g.c0),
          _vLine(g.r0, g.r1, g.c0),
        ]),
      ];
    }
    return [
      _join([
        _hLine(g.r1, g.c0, g.c1),
        _vLine(g.r1, g.r0, g.c1),
      ]),
    ];
  }

  static List<List<Cell>> _u(GridRegion g, {required bool invert}) {
    if (invert) {
      return [
        _join([
          _vLine(g.r1, g.r0, g.c0),
          _hLine(g.r0, g.c0, g.c1),
          _vLine(g.r0, g.r1, g.c1),
        ]),
      ];
    }
    return [
      _join([
        _vLine(g.r0, g.r1, g.c0),
        _hLine(g.r1, g.c0, g.c1),
        _vLine(g.r1, g.r0, g.c1),
      ]),
    ];
  }

  static List<List<Cell>> _c(GridRegion g) {
    return [
      _join([
        _hLine(g.r0, g.c1, g.c0),
        _vLine(g.r0, g.r1, g.c0),
        _hLine(g.r1, g.c0, g.c1),
      ]),
    ];
  }

  static List<List<Cell>> _s(GridRegion g) {
    final mid = g.cr;
    return [
      _join([
        _hLine(g.r0, g.c1, g.c0),
        _vLine(g.r0, mid, g.c0),
        _hLine(mid, g.c0, g.c1),
        _vLine(mid, g.r1, g.c1),
        _hLine(g.r1, g.c1, g.c0),
      ]),
    ];
  }

  static List<List<Cell>> _z(GridRegion g) {
    final mid = g.cr;
    return [
      _join([
        _hLine(g.r0, g.c0, g.c1),
        _vLine(g.r0, mid, g.c1),
        _hLine(mid, g.c1, g.c0),
        _vLine(mid, g.r1, g.c0),
        _hLine(g.r1, g.c0, g.c1),
      ]),
    ];
  }

  static List<List<Cell>> _w(GridRegion g) {
    if (g.width < 5) return _zigzag(g);
    final c1 = g.c0 + g.width ~/ 4;
    final c2 = g.cc;
    final c3 = g.c1 - g.width ~/ 4;
    return [
      _join([
        _vLine(g.r0, g.r1, g.c0),
        _hLine(g.r1, g.c0, c1),
        _vLine(g.r1, g.r0, c1),
        _hLine(g.r0, c1, c2),
        _vLine(g.r0, g.r1, c2),
        _hLine(g.r1, c2, c3),
        _vLine(g.r1, g.r0, c3),
        _hLine(g.r0, c3, g.c1),
        _vLine(g.r0, g.r1, g.c1),
      ]),
    ];
  }

  static List<List<Cell>> _m(GridRegion g) {
    if (g.width < 4) return _hLetter(g);
    final c1 = g.c0 + g.width ~/ 3;
    final c2 = g.c1 - g.width ~/ 3;
    return [
      _join([
        _vLine(g.r1, g.r0, g.c0),
        _hLine(g.r0, g.c0, c1),
        _vLine(g.r0, g.r1, c1),
        _hLine(g.r1, c1, c2),
        _vLine(g.r1, g.r0, c2),
        _hLine(g.r0, c2, g.c1),
        _vLine(g.r0, g.r1, g.c1),
      ]),
    ];
  }

  static List<List<Cell>> _vLetter(GridRegion g, {required bool invert}) {
    final mid = g.cc;
    if (invert) {
      return [
        _join([
          _hLine(g.r1, g.c0, mid),
          _vLine(g.r1, g.r0, mid),
          _hLine(g.r0, mid, g.c1),
        ]),
      ];
    }
    return [
      _join([
        [(g.r0, g.c0)],
        _staircaseFrom(g.r0, g.c0, g.r1, mid),
        _staircaseFrom(g.r1, mid, g.r0, g.c1).skip(1).toList(),
      ]),
    ];
  }

  static List<List<Cell>> _rect(GridRegion g, {required bool square}) {
    var region = g;
    if (square) {
      final n = min(g.height, g.width);
      final r0 = g.cr - n ~/ 2;
      final c0 = g.cc - n ~/ 2;
      region = GridRegion(r0, c0, r0 + n - 1, c0 + n - 1);
    }
    if (region.height < 3 || region.width < 3) {
      return [_hLine(region.cr, region.c0, region.c1)];
    }
    return [_perimeter(region, open: true)];
  }

  static List<List<Cell>> _roundedRect(GridRegion g) {
    if (g.height < 4 || g.width < 4) return _rect(g, square: false);
    final loop = _perimeter(
      GridRegion(g.r0 + 1, g.c0, g.r1 - 1, g.c1),
      open: true,
    );
    return [loop];
  }

  static List<List<Cell>> _doubleRect(GridRegion g) {
    if (g.width < 6) return _rect(g, square: false);
    final mid = g.cc;
    final left = GridRegion(g.r0, g.c0, g.r1, mid);
    final right = GridRegion(g.r0, mid, g.r1, g.c1);
    return [
      _perimeter(left, open: true),
      _perimeter(right, open: true),
    ];
  }

  static List<List<Cell>> _nestedRect(GridRegion g) {
    final outer = _perimeter(g, open: true);
    if (g.height < 5 || g.width < 5) return [outer];
    final inner = GridRegion(g.r0 + 2, g.c0 + 2, g.r1 - 2, g.c1 - 2);
    return [outer, _perimeter(inner, open: true)];
  }

  static List<List<Cell>> _diamond(GridRegion g, {required int rings}) {
    final paths = <List<Cell>>[];
    final maxR = min(g.height, g.width) ~/ 2;
    if (maxR < 1) return _straightH(g);
    final count = rings == 1 ? 1 : min(2, maxR);
    for (var k = 0; k < count; k++) {
      final rad = maxR - k * (maxR > 2 ? 2 : 1);
      if (rad < 1) continue;
      paths.add(_diamondRing(g.cr, g.cc, rad, g));
    }
    return paths;
  }

  static List<Cell> _diamondRing(int cr, int cc, int rad, GridRegion g) {
    final cells = <Cell>[];
    void add(int r, int c) {
      if (r >= g.r0 && r <= g.r1 && c >= g.c0 && c <= g.c1) {
        if (cells.isEmpty || cells.last != (r, c)) cells.add((r, c));
      }
    }

    for (var i = 0; i < rad; i++) {
      add(cr - rad + i, cc + i);
    }
    for (var i = 0; i < rad; i++) {
      add(cr + i, cc + rad - i);
    }
    for (var i = 0; i < rad; i++) {
      add(cr + rad - i, cc - i);
    }
    for (var i = 0; i < rad; i++) {
      add(cr - i, cc - rad + i);
    }
    return cells;
  }

  static List<List<Cell>> _triangle(GridRegion g, {required bool invert}) {
    final mid = g.cc;
    if (invert) {
      return [
        _join([
          _hLine(g.r0, g.c0, g.c1),
          _staircaseFrom(g.r0, g.c1, g.r1, mid),
          _staircaseFrom(g.r1, mid, g.r0, g.c0),
        ]),
      ];
    }
    return [
      _join([
        _hLine(g.r1, g.c0, g.c1),
        _staircaseFrom(g.r1, g.c1, g.r0, mid),
        _staircaseFrom(g.r0, mid, g.r1, g.c0),
      ]),
    ];
  }

  static List<List<Cell>> _plus(GridRegion g) {
    return [
      _hLine(g.cr, g.c0, g.c1),
      _vLine(g.r0, g.r1, g.cc),
    ];
  }

  static List<List<Cell>> _t(GridRegion g) {
    return [
      _hLine(g.r0, g.c0, g.c1),
      _vLine(g.r0, g.r1, g.cc),
    ];
  }

  static List<List<Cell>> _hLetter(GridRegion g) {
    return [
      _vLine(g.r0, g.r1, g.c0),
      _hLine(g.cr, g.c0, g.c1),
      _vLine(g.r0, g.r1, g.c1),
    ];
  }

  static List<List<Cell>> _x(GridRegion g) {
    return [
      _staircaseFrom(g.r0, g.c0, g.r1, g.c1),
      _staircaseFrom(g.r0, g.c1, g.r1, g.c0),
    ];
  }

  static List<List<Cell>> _star(GridRegion g) {
    return [
      ..._plus(g),
      ..._diamond(g, rings: 1),
    ];
  }

  static List<List<Cell>> _spiral(GridRegion g, {required bool reverse}) {
    var r0 = g.r0, c0 = g.c0, r1 = g.r1, c1 = g.c1;
    final cells = <Cell>[];
    var dir = 0;
    while (r0 <= r1 && c0 <= c1) {
      switch (dir % 4) {
        case 0:
          cells.addAll(_hLine(r0, c0, c1));
          r0++;
        case 1:
          cells.addAll(_vLine(r0, r1, c1));
          c1--;
        case 2:
          cells.addAll(_hLine(r1, c1, c0));
          r1--;
        case 3:
          cells.addAll(_vLine(r1, r0, c0));
          c0++;
      }
      dir++;
    }
    final path = _dedupeAdjacent(cells);
    return [reverse ? path.reversed.toList() : path];
  }

  static List<List<Cell>> _snake(GridRegion g) {
    final cells = <Cell>[];
    for (var r = g.r0; r <= g.r1; r++) {
      final even = (r - g.r0).isEven;
      cells.addAll(even ? _hLine(r, g.c0, g.c1) : _hLine(r, g.c1, g.c0));
    }
    return [_dedupeAdjacent(cells)];
  }

  static List<List<Cell>> _zigzag(GridRegion g) {
    final cells = <Cell>[(g.r0, g.c0)];
    var r = g.r0;
    var goingDown = true;
    for (var c = g.c0 + 1; c <= g.c1; c++) {
      final nextR = goingDown
          ? min(g.r1, r + 1)
          : max(g.r0, r - 1);
      if (nextR == r) goingDown = !goingDown;
      r = goingDown ? min(g.r1, r + 1) : max(g.r0, r - 1);
      cells.add((r, c));
      goingDown = !goingDown;
    }
    return [_dedupeAdjacent(cells)];
  }

  static List<List<Cell>> _staircase(GridRegion g) {
    return [_staircaseFrom(g.r0, g.c0, g.r1, g.c1)];
  }

  static List<Cell> _staircaseFrom(int r0, int c0, int r1, int c1) {
    final cells = <Cell>[(r0, c0)];
    var r = r0;
    var c = c0;
    final dr = r1 >= r0 ? 1 : -1;
    final dc = c1 >= c0 ? 1 : -1;
    var horizontal = true;
    while (r != r1 || c != c1) {
      if (horizontal && c != c1) {
        c += dc;
      } else if (!horizontal && r != r1) {
        r += dr;
      } else if (c != c1) {
        c += dc;
      } else {
        r += dr;
      }
      cells.add((r, c));
      horizontal = !horizontal;
    }
    return _dedupeAdjacent(cells);
  }

  static List<List<Cell>> _wave(GridRegion g) {
    final amp = max(1, g.height ~/ 3);
    final cells = <Cell>[];
    for (var c = g.c0; c <= g.c1; c++) {
      final phase = (c - g.c0) % (amp * 2);
      final r = phase <= amp ? g.cr - (amp - phase) : g.cr + (phase - amp);
      final clamped = r.clamp(g.r0, g.r1);
      if (cells.isEmpty) {
        cells.add((clamped, c));
      } else {
        cells.addAll(_connect(cells.last, (clamped, c)));
      }
    }
    return [_dedupeAdjacent(cells)];
  }

  static List<List<Cell>> _ring(GridRegion g) {
    if (g.height < 3 || g.width < 3) return _rect(g, square: true);
    return [_perimeter(g, open: true)];
  }

  static List<List<Cell>> _doubleRing(GridRegion g) => _nestedRect(g);

  static List<List<Cell>> _brokenCircle(GridRegion g) {
    final loop = _perimeter(g, open: true);
    if (loop.length < 6) return [loop];
    final gap = max(2, loop.length ~/ 8);
    return [loop.sublist(0, loop.length - gap)];
  }

  static List<List<Cell>> _semiCircle(GridRegion g) {
    return [
      _join([
        _hLine(g.r1, g.c0, g.c1),
        _vLine(g.r1, g.r0, g.c1),
        _hLine(g.r0, g.c1, g.c0),
      ]),
    ];
  }

  static List<List<Cell>> _clock(GridRegion g) {
    final paths = <List<Cell>>[_perimeter(g, open: true)];
    final tick = max(1, min(g.height, g.width) ~/ 4);
    paths.add(_vLine(g.r0, g.r0 + tick, g.cc));
    paths.add(_vLine(g.r1 - tick, g.r1, g.cc));
    paths.add(_hLine(g.cr, g.c0, g.c0 + tick));
    paths.add(_hLine(g.cr, g.c1 - tick, g.c1));
    return paths;
  }

  static List<List<Cell>> _flower(GridRegion g) {
    final paths = [..._plus(g)];
    if (min(g.height, g.width) >= 5) {
      paths.addAll(_diamond(g, rings: 1));
    }
    return paths;
  }

  static List<List<Cell>> _pinwheel(GridRegion g) {
    final cr = g.cr;
    final cc = g.cc;
    return [
      _join([_hLine(cr, cc, g.c1), _vLine(cr, g.r0, g.c1)]),
      _join([_vLine(cr, g.r0, cc), _hLine(g.r0, cc, g.c0)]),
      _join([_hLine(cr, cc, g.c0), _vLine(cr, g.r1, g.c0)]),
      _join([_vLine(cr, g.r1, cc), _hLine(g.r1, cc, g.c1)]),
    ];
  }

  static List<List<Cell>> _maze(GridRegion g, Random rng) {
    final paths = <List<Cell>>[];
    for (var r = g.r0; r <= g.r1; r += 2) {
      paths.add(_hLine(r, g.c0, g.c1));
    }
    for (var c = g.c0 + 1; c < g.c1; c += 2) {
      final r0 = g.r0 + rng.nextInt(max(1, g.height ~/ 2));
      final r1 = min(g.r1, r0 + 1 + rng.nextInt(max(1, g.height ~/ 2)));
      paths.add(_vLine(r0, r1, c));
    }
    return paths;
  }

  static List<List<Cell>> _infinity(GridRegion g) {
    if (g.width < 5) return _ring(g);
    final mid = g.cc;
    final left = GridRegion(g.r0, g.c0, g.r1, mid);
    final right = GridRegion(g.r0, mid, g.r1, g.c1);
    return [
      _perimeter(left, open: true),
      _perimeter(right, open: true),
    ];
  }

  static List<List<Cell>> _arrowhead(GridRegion g) {
    final mid = g.cc;
    return [
      _vLine(g.r1, g.cr, mid),
      _join([
        _staircaseFrom(g.cr, g.c0, g.r0, mid),
        _staircaseFrom(g.r0, mid, g.cr, g.c1),
      ]),
    ];
  }

  static List<List<Cell>> _bowtie(GridRegion g) {
    final mid = g.cc;
    return [
      _join([
        _staircaseFrom(g.r0, g.c0, g.cr, mid),
        _staircaseFrom(g.cr, mid, g.r1, g.c0),
      ]),
      _join([
        _staircaseFrom(g.r0, g.c1, g.cr, mid),
        _staircaseFrom(g.cr, mid, g.r1, g.c1),
      ]),
    ];
  }

  static List<List<Cell>> _crown(GridRegion g) {
    if (g.width < 5) return _u(g, invert: false);
    final c1 = g.c0 + g.width ~/ 4;
    final c2 = g.cc;
    final c3 = g.c1 - g.width ~/ 4;
    return [
      _join([
        _vLine(g.r1, g.r0, g.c0),
        _hLine(g.r0, g.c0, c1),
        _vLine(g.r0, g.cr, c1),
        _hLine(g.cr, c1, c2),
        _vLine(g.cr, g.r0, c2),
        _hLine(g.r0, c2, c3),
        _vLine(g.r0, g.cr, c3),
        _hLine(g.cr, c3, g.c1),
        _vLine(g.cr, g.r1, g.c1),
        _hLine(g.r1, g.c1, g.c0),
      ]),
    ];
  }

  static List<List<Cell>> _lightning(GridRegion g) {
    final c1 = g.c0 + g.width ~/ 3;
    final c2 = g.c1 - g.width ~/ 3;
    return [
      _join([
        _vLine(g.r0, g.cr, g.c0),
        _hLine(g.cr, g.c0, c2),
        _vLine(g.cr, g.r1, c2),
        _hLine(g.r1, c2, g.c1),
        _hLine(g.r0, g.c1, c1),
      ]),
    ];
  }

  static List<Cell> _connect(Cell a, Cell b) {
    final (r0, c0) = a;
    final (r1, c1) = b;
    final cells = <Cell>[a];
    var r = r0;
    var c = c0;
    while (c != c1) {
      c += c1 > c ? 1 : -1;
      cells.add((r, c));
    }
    while (r != r1) {
      r += r1 > r ? 1 : -1;
      cells.add((r, c));
    }
    return cells.skip(1).toList();
  }

  static List<Cell> _dedupeAdjacent(List<Cell> cells) {
    if (cells.isEmpty) return cells;
    final out = <Cell>[cells.first];
    for (final cell in cells.skip(1)) {
      if (cell != out.last) out.add(cell);
    }
    return out;
  }

  static List<List<Cell>> _sanitize(List<List<Cell>> paths, GridRegion g) {
    final out = <List<Cell>>[];
    for (final path in paths) {
      final clipped = [
        for (final cell in path)
          if (g.contains(cell)) cell,
      ];
      out.addAll(_splitConnected(_dedupeAdjacent(clipped)));
    }
    return [for (final p in out) if (p.length >= 2) p];
  }

  static List<List<Cell>> _splitConnected(List<Cell> path) {
    if (path.length < 2) return path.isEmpty ? const [] : [path];
    final runs = <List<Cell>>[];
    var current = <Cell>[path.first];
    for (var i = 1; i < path.length; i++) {
      final a = current.last;
      final b = path[i];
      final dist = (a.$1 - b.$1).abs() + (a.$2 - b.$2).abs();
      if (dist == 1) {
        current.add(b);
      } else {
        if (current.length >= 2) runs.add(current);
        current = [b];
      }
    }
    if (current.length >= 2) runs.add(current);
    return runs;
  }
}
