import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../logic/puzzle_engine.dart';
import '../models/level.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../services/sfx_service.dart';

typedef GameEventCallback = void Function(GameEvent event);

sealed class GameEvent {}

class MoveCompleted extends GameEvent {
  MoveCompleted({
    required this.outcome,
    required this.moveCount,
    required this.blockedCount,
  });

  final MoveOutcome outcome;
  final int moveCount;
  final int blockedCount;
}

class LevelWon extends GameEvent {
  LevelWon({
    required this.moveCount,
    required this.blockedCount,
    required this.elapsedSeconds,
  });

  final int moveCount;
  final int blockedCount;
  final int elapsedSeconds;
}

class HintShown extends GameEvent {
  HintShown(this.snakeId);
  final int snakeId;
}

class BoardReady extends GameEvent {}

class ArrowChallengeGame extends FlameGame {
  ArrowChallengeGame({
    required this.level,
    required this.onEvent,
    this.canPlay,
  });

  final LevelDefinition level;
  final GameEventCallback onEvent;
  final bool Function()? canPlay;

  late PuzzleEngine _engine;
  late BoardComponent _board;
  late DateTime _startTime;
  bool _boardReady = false;

  PuzzleEngine get engine => _engine;
  int get elapsedSeconds => DateTime.now().difference(_startTime).inSeconds;
  bool get boardReady => _boardReady;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _engine = PuzzleEngine.fromLevel(level);
    _startTime = DateTime.now();
    _board = BoardComponent(
      engine: _engine,
      onSnakeTap: _handleSnakeTap,
      onIntroComplete: () {
        _boardReady = true;
        _startTime = DateTime.now();
        onEvent(BoardReady());
      },
    );
    add(_board);
    _board.updateLayout(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) return;
    _board.updateLayout(size);
  }

  Future<void> _handleSnakeTap(int snakeId) async {
    if (!_boardReady) return;
    if (canPlay != null && !canPlay!()) return;

    final preview = _engine.previewMove(snakeId);

    if (preview.result == MoveResult.blocked) {
      SettingsService.instance.hapticMedium();
      _engine.blockedCount++;
      await _board.flashWrongMove(snakeId);
      onEvent(MoveCompleted(
        outcome: preview,
        moveCount: _engine.moveCount,
        blockedCount: _engine.blockedCount,
      ));
      return;
    }

    if (!preview.didMove) return;

    SettingsService.instance.hapticLight();

    SfxService.instance.playSwipe();
    final result = _engine.tryMove(snakeId);
    _board.clearHint();

    onEvent(MoveCompleted(
      outcome: result,
      moveCount: _engine.moveCount,
      blockedCount: _engine.blockedCount,
    ));

    await _board.slideOutSnake(snakeId, preview.rayCells);

    if (result.result == MoveResult.won) {
      onEvent(LevelWon(
        moveCount: _engine.moveCount,
        blockedCount: _engine.blockedCount,
        elapsedSeconds: elapsedSeconds,
      ));
    }
  }

  void restartLevel() {
    _boardReady = false;
    _engine = PuzzleEngine.fromLevel(level);
    _startTime = DateTime.now();
    _board.setEngine(_engine);
  }

  Future<bool> showHint() async {
    final snakeId = _engine.findHintSnakeId();
    if (snakeId == null) return false;

    final used = await ProgressService.instance.useHint();
    if (!used) return false;

    _board.showHint(snakeId);
    onEvent(HintShown(snakeId));
    return true;
  }
}

class BoardComponent extends PositionComponent {
  BoardComponent({
    required PuzzleEngine engine,
    required this.onSnakeTap,
    required this.onIntroComplete,
  }) : _engine = engine; // ignore: prefer_initializing_formals

  static const cardColor = Color(0xFFF7F8FC);
  static const trailDotColor = Color(0xFFC5C8D4);

  PuzzleEngine _engine;
  final Future<void> Function(int snakeId) onSnakeTap;
  final VoidCallback onIntroComplete;

  final Map<int, SnakeComponent> _snakeComponents = {};
  final Set<Cell> _trailCells = {};
  double _cellSize = 48;
  double _margin = 16;
  bool _introPlayed = false;
  bool _introRunning = false;
  double _laidOutCell = -1;

  void setEngine(PuzzleEngine engine) {
    _engine = engine;
    _introPlayed = false;
    _laidOutCell = -1;
    _rebuildSnakes();
  }

  void updateLayout(Vector2 gameSize) {
    const outerPadding = 12.0;
    final maxW = gameSize.x - outerPadding * 2;
    final maxH = gameSize.y - outerPadding * 2;

    final cellW = maxW / (_engine.cols + 0.5);
    final cellH = maxH / (_engine.rows + 0.5);
    final cellSize = (cellW < cellH ? cellW : cellH).clamp(16.0, 110.0);
    final margin = cellSize * 0.28;

    final cardW = cellSize * _engine.cols + margin * 2;
    final cardH = cellSize * _engine.rows + margin * 2;

    size = Vector2(cardW, cardH);
    position = Vector2(
      (gameSize.x - cardW) / 2,
      (gameSize.y - cardH) / 2,
    );

    // Heart/timer setState rebuilds GameWidget and retriggers resize.
    // Recreating snakes here was wiping the red wrong-move flash.
    final sameLayout =
        (cellSize - _laidOutCell).abs() < 0.05 && _snakeComponents.isNotEmpty;
    _cellSize = cellSize;
    _margin = margin;
    if (sameLayout) return;

    _laidOutCell = cellSize;
    _rebuildSnakes();
  }

  void _rebuildSnakes() {
    for (final c in _snakeComponents.values) {
      c.removeFromParent();
    }
    _snakeComponents.clear();
    _trailCells
      ..clear()
      ..addAll([
        for (final snake in _engine.snakes) ...snake.cells,
      ]);

    final snakes = _engine.snakes;
    for (var i = 0; i < snakes.length; i++) {
      final snake = snakes[i];
      final component = SnakeComponent(
        snake: snake,
        cellSize: _cellSize,
        clipMargin: _margin,
        onTap: () => onSnakeTap(snake.id),
        introDelay: _introPlayed ? 0 : i * 0.022,
        introDuration: _introPlayed ? 0 : 0.38,
      )
        ..anchor = Anchor.center
        ..position = Vector2(
          _margin + _cellSize * _engine.cols / 2,
          _margin + _cellSize * _engine.rows / 2,
        )
        ..size = Vector2(
          _cellSize * _engine.cols,
          _cellSize * _engine.rows,
        );
      if (_introPlayed) component.skipIntro();
      _snakeComponents[snake.id] = component;
      add(component);
    }

    if (!_introPlayed && !_introRunning) {
      _introRunning = true;
      _waitForIntro();
    }
  }

  Future<void> _waitForIntro() async {
    final count = _snakeComponents.length;
    final wait = count == 0 ? 0.2 : count * 0.022 + 0.42;
    await Future<void>.delayed(Duration(milliseconds: (wait * 1000).round()));
    _introPlayed = true;
    _introRunning = false;
    onIntroComplete();
  }

  Future<void> slideOutSnake(int snakeId, int rayCells) async {
    final component = _snakeComponents.remove(snakeId);
    if (component == null) return;
    await component.slideOut(rayCells);
  }

  Future<void> flashWrongMove(int snakeId) async {
    _snakeComponents[snakeId]?.flashWrong();

    add(
      MoveEffect.by(
        Vector2(_cellSize * 0.12, 0),
        EffectController(
          duration: 0.045,
          alternate: true,
          repeatCount: 4,
          curve: Curves.easeInOut,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 420));
  }

  void showHint(int snakeId) {
    _snakeComponents[snakeId]?.setHighlighted(true);
  }

  void clearHint() {
    for (final c in _snakeComponents.values) {
      c.setHighlighted(false);
    }
  }

  @override
  void render(Canvas canvas) {
    final radius = Radius.circular(_cellSize * 0.38);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = cardColor,
    );

    _drawTrailDots(canvas);

    super.render(canvas);
  }

  void _drawTrailDots(Canvas canvas) {
    final radius = _cellSize * 0.075;
    final paint = Paint()..color = trailDotColor;
    for (final (row, col) in _trailCells) {
      canvas.drawCircle(
        Offset(
          _margin + (col + 0.5) * _cellSize,
          _margin + (row + 0.5) * _cellSize,
        ),
        radius,
        paint,
      );
    }
  }
}

class SnakeComponent extends PositionComponent with TapCallbacks {
  SnakeComponent({
    required this.snake,
    required this.cellSize,
    required this.clipMargin,
    required this.onTap,
    this.introDelay = 0,
    this.introDuration = 0.35,
  }) {
    _basePoints = [
      for (final (r, c) in snake.cells)
        Offset((c + 0.5) * cellSize, (r + 0.5) * cellSize),
    ];
    _bodyLength = _polylineLength(_basePoints);
  }

  static const arrowColor = Color(0xFF1A1A1A);
  static const hintColor = Color(0xFFFFC831);
  static const wrongColor = Color(0xFFE53935);

  final ArrowSnake snake;
  final double cellSize;
  final double clipMargin;
  final VoidCallback onTap;
  final double introDelay;
  final double introDuration;

  late final List<Offset> _basePoints;
  late final double _bodyLength;

  bool _highlighted = false;
  double _reveal = 0;
  double _introTime = 0;
  bool _introDone = false;
  double _wrongT = 0;
  double _wrongHold = 0;

  List<Offset>? _slidePoints;
  double _slideOffset = 0;
  double _slideTotal = 0;
  double _slideTime = 0;
  double _slideDuration = 0;
  Completer<void>? _slideCompleter;

  bool get _sliding => _slidePoints != null;

  void skipIntro() {
    _reveal = 1;
    _introDone = true;
  }

  void setHighlighted(bool value) => _highlighted = value;

  void flashWrong() {
    _wrongT = 1;
    _wrongHold = 0.28;
    priority = 20;
    final (dr, dc) = snake.heading.delta;
    final nudge = Vector2(dc * cellSize * 0.14, dr * cellSize * 0.14);
    add(
      MoveEffect.by(
        nudge,
        EffectController(
          duration: 0.05,
          alternate: true,
          repeatCount: 3,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  Future<void> slideOut(int rayCells) {
    final (dr, dc) = snake.heading.delta;
    final dir = Offset(dc.toDouble(), dr.toDouble());

    _slideTotal = rayCells * cellSize +
        cellSize * 0.5 +
        clipMargin +
        _bodyLength +
        cellSize;
    _slidePoints = [
      ..._basePoints,
      _basePoints.last + dir * _slideTotal,
    ];
    _slideOffset = 0;
    _slideTime = 0;
    _slideDuration = 0.22 + _slideTotal / (cellSize * 26);
    _slideCompleter = Completer<void>();
    priority = 10;
    return _slideCompleter!.future;
  }

  void pulse() {
    add(
      ScaleEffect.by(
        Vector2.all(1.04),
        EffectController(
          duration: 0.07,
          reverseDuration: 0.08,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_introDone) {
      _introTime += dt;
      final t = ((_introTime - introDelay) / max(0.01, introDuration))
          .clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(t);
      _reveal = eased;
      if (t >= 1) _introDone = true;
    }

    if (_wrongHold > 0) {
      _wrongHold = (_wrongHold - dt).clamp(0.0, 1.0);
      _wrongT = 1;
    } else if (_wrongT > 0) {
      _wrongT = (_wrongT - dt / 0.4).clamp(0.0, 1.0);
      if (_wrongT == 0) priority = 0;
    }

    if (!_sliding) return;

    _slideTime += dt;
    final t = (_slideTime / _slideDuration).clamp(0.0, 1.0);
    _slideOffset = _slideTotal * t * t;

    if (t >= 1) {
      removeFromParent();
    }
  }

  @override
  void onRemove() {
    if (_slideCompleter != null && !_slideCompleter!.isCompleted) {
      _slideCompleter!.complete();
    }
    super.onRemove();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (_sliding || !_introDone) return false;
    for (final (r, c) in snake.cells) {
      final rect = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);
      if (rect.contains(Offset(point.x, point.y))) return true;
    }
    return false;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_introDone) return;
    pulse();
    onTap();
  }

  @override
  void render(Canvas canvas) {
    final gridW = size.x;
    final gridH = size.y;

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -clipMargin,
          -clipMargin,
          gridW + clipMargin * 2,
          gridH + clipMargin * 2,
        ),
        Radius.circular(cellSize * 0.38),
      ),
    );

    List<Offset> points;
    if (_sliding) {
      points = _polylineWindow(
        _slidePoints!,
        _slideOffset,
        _slideOffset + _bodyLength,
      );
    } else if (_reveal < 1) {
      points = _polylineWindow(_basePoints, 0, _bodyLength * _reveal);
    } else {
      points = _basePoints;
    }

    if (points.length >= 2) {
      _drawSnake(canvas, points);
    }

    canvas.restore();
  }

  void _drawSnake(Canvas canvas, List<Offset> points) {
    final head = points.last;
    final beforeHead = points[points.length - 2];
    final dist = (head - beforeHead).distance;
    if (dist < 0.001) return;
    final dir = (head - beforeHead) / dist;

    final color = _wrongT > 0
        ? Color.lerp(arrowColor, wrongColor, Curves.easeOut.transform(_wrongT))!
        : arrowColor;

    final strokeEnd = head - dir * (cellSize * 0.10);
    final strokePoints = [...points]..last = strokeEnd;

    final path = Path()..moveTo(strokePoints.first.dx, strokePoints.first.dy);
    for (final p in strokePoints.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final tip = head + dir * (cellSize * 0.32);
    final base = head - dir * (cellSize * 0.08);
    final perp = Offset(-dir.dy, dir.dx) * (cellSize * 0.16);
    final arrowhead = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx, base.dy + perp.dy)
      ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
      ..close();

    if (_highlighted) {
      final glow = Paint()
        ..color = hintColor.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.28
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glow);
      canvas.drawPath(arrowhead, glow..style = PaintingStyle.fill);
    }

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * (0.18 + 0.10 * _wrongT)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);
    canvas.drawPath(arrowhead, Paint()..color = color);
  }

  static double _polylineLength(List<Offset> pts) {
    var length = 0.0;
    for (var i = 0; i < pts.length - 1; i++) {
      length += (pts[i + 1] - pts[i]).distance;
    }
    return length;
  }

  static List<Offset> _polylineWindow(
    List<Offset> pts,
    double start,
    double end,
  ) {
    final out = <Offset>[];
    var acc = 0.0;

    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final segLen = (p1 - p0).distance;
      if (segLen == 0) continue;

      final segStart = acc;
      final segEnd = acc + segLen;
      acc = segEnd;

      if (segEnd < start) continue;
      if (segStart > end) break;

      final t0 = ((start - segStart) / segLen).clamp(0.0, 1.0);
      final t1 = ((end - segStart) / segLen).clamp(0.0, 1.0);

      if (out.isEmpty) {
        out.add(Offset.lerp(p0, p1, t0)!);
      }
      out.add(Offset.lerp(p0, p1, t1)!);
    }
    return out;
  }
}
