import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/arrow_challenge_game.dart';
import '../levels/level_repository.dart';
import '../logic/puzzle_engine.dart';
import '../models/level.dart';
import '../services/ad_service.dart';
import '../services/progress_service.dart';
import '../widgets/common_widgets.dart';
import 'victory_screen.dart';

const _navy = AppTheme.navy;
const _heartRed = AppTheme.heartRed;
const _heartEmpty = Color(0xFFB9C0DE);

const _maxHearts = 3;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelId});

  final int levelId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final level = LevelRepository.getLevel(widget.levelId);
  late final ArrowChallengeGame _game;
  late final int _timeLimit = level.timeLimitSeconds;

  int _hearts = _maxHearts;
  int _secondsRemaining = 0;
  bool _dialogOpen = false;
  bool _timedOut = false;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _timeLimit;
    _game = ArrowChallengeGame(
      level: level,
      onEvent: _handleEvent,
      canPlay: () => !_timedOut && !_dialogOpen && _game.boardReady,
    );
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _dialogOpen || _timedOut) return;

    if (_secondsRemaining <= 1) {
      setState(() => _secondsRemaining = 0);
      _onTimeUp();
      return;
    }

    setState(() => _secondsRemaining--);
  }

  void _onTimeUp() {
    if (_timedOut || _game.engine.isComplete) return;

    _timedOut = true;
    _countdown?.cancel();
    _showTimeUp();
  }

  void _handleEvent(GameEvent event) {
    if (!mounted || _timedOut) return;

    if (event is BoardReady) {
      _startCountdown();
      return;
    }

    if (event is MoveCompleted) {
      if (event.outcome.result == MoveResult.blocked) {
        setState(() => _hearts = (_hearts - 1).clamp(0, _maxHearts));
        if (_hearts == 0) _showOutOfHearts();
      } else {
        setState(() {});
      }
    } else if (event is LevelWon) {
      _countdown?.cancel();
      _onLevelWon(event);
    }
  }

  void _restart() {
    _countdown?.cancel();
    _timedOut = false;
    _game.restartLevel();
    setState(() {
      _hearts = _maxHearts;
      _secondsRemaining = _timeLimit;
    });
  }

  Future<void> _retryWithRewardedAd() async {
    Navigator.pop(context);
    final rewarded = await AdService.instance.showRewardedForRetry();
    if (!mounted) return;
    if (rewarded) {
      _restart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Watch the full video to try again.',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
  }

  Future<void> _onLevelWon(LevelWon event) async {
    await ProgressService.instance.completeLevel(
      levelId: widget.levelId,
      moves: event.moveCount,
      parMoves: level.parMoves,
      blocked: event.blockedCount,
    );

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => VictoryScreen(
          levelId: widget.levelId,
          moves: event.moveCount,
          parMoves: level.parMoves,
          elapsedSeconds: event.elapsedSeconds,
          blocked: event.blockedCount,
        ),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _showOutOfHearts() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    _countdown?.cancel();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.bg.withValues(alpha: 0.88),
      builder: (context) => WoodGameDialog(
        title: 'Out of Hearts!',
        subtitle: 'Too many blocked arrows.\nGive it another try!',
        actions: [
          ChunkyButton(
            label: 'WATCH & RETRY',
            fontSize: 18,
            width: double.infinity,
            onPressed: _retryWithRewardedAd,
          ),
          WoodDialogButton(
            label: 'Quit',
            primary: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(this.context);
            },
          ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  Future<void> _showTimeUp() async {
    if (_dialogOpen) return;
    _dialogOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.bg.withValues(alpha: 0.88),
      builder: (context) => WoodGameDialog(
        title: "Time's Up!",
        subtitle:
            'Watch a short video to try again,\nor quit to leave the level.',
        actions: [
          ChunkyButton(
            label: 'WATCH & RETRY',
            fontSize: 20,
            width: double.infinity,
            onPressed: _retryWithRewardedAd,
          ),
          ChunkyButton(
            label: 'QUIT',
            blue: true,
            fontSize: 20,
            width: double.infinity,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context);
            },
          ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lowTime = _secondsRemaining <= 5;

    return PastelBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    WoodControlButton(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.woodInk,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'LEVEL ${widget.levelId}',
                            style: GoogleFonts.fredoka(
                              color: _navy,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_maxHearts, (i) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: 34,
                                  color:
                                      i < _hearts ? _heartRed : _heartEmpty,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 22,
                                color: lowTime
                                    ? AppTheme.heartRed
                                    : _navy.withValues(alpha: 0.55),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatTime(_secondsRemaining),
                                style: GoogleFonts.fredoka(
                                  color: lowTime ? AppTheme.heartRed : _navy,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    WoodControlButton(
                      onTap: _restart,
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.woodInk,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GameWidget(game: _game),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
