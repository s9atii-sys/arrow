import 'package:audioplayers/audioplayers.dart';

import 'settings_service.dart';

/// Plays short sound effects safely:
/// - A fixed pool of players is created once and reused, so repeated moves
///   never allocate new native players (no memory growth).
/// - Each player loads the asset a single time (`ReleaseMode.stop` keeps the
///   source in memory instead of re-decoding it on every play).
/// - Every call is wrapped in try/catch: audio can fail (missing asset,
///   audio focus loss, backgrounded app) but must never crash the game.
class SfxService {
  SfxService._();
  static final instance = SfxService._();

  static const _poolSize = 3;

  final List<AudioPlayer> _players = [];
  int _next = 0;
  bool _ready = false;
  Future<void>? _initFuture;

  /// Safe to call multiple times; initialization only runs once.
  Future<void> preload() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      AudioLogger.logLevel = AudioLogLevel.none;
      for (var i = 0; i < _poolSize; i++) {
        final player = AudioPlayer(playerId: 'sfx_swipe_$i');
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource('audio/swipe.wav'));
        await player.setVolume(0.9);
        _players.add(player);
      }
      _ready = true;
    } catch (_) {
      // Sound stays off for this session; gameplay continues normally.
      await _disposePlayers();
    }
  }

  Future<void> playSwipe() async {
    try {
      await preload();
      if (!_ready || _players.isEmpty) return;
      if (!SettingsService.instance.soundEnabled) return;

      final player = _players[_next];
      _next = (_next + 1) % _players.length;
      await player.stop();
      await player.resume();
    } catch (_) {
      // Never let a playback failure break a move.
    }
  }

  /// Releases all native players. Call when the app is shutting down.
  Future<void> dispose() async {
    _ready = false;
    _initFuture = null;
    await _disposePlayers();
  }

  Future<void> _disposePlayers() async {
    final players = List.of(_players);
    _players.clear();
    _ready = false;
    for (final player in players) {
      try {
        await player.dispose();
      } catch (_) {
        // Ignore: disposing a failed player must not throw.
      }
    }
  }
}
