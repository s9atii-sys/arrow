import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted player preferences (sound, vibration) and haptic helpers.
class SettingsService {
  SettingsService._();
  static final instance = SettingsService._();

  static const _soundKey = 'settings_sound';
  static const _vibrationKey = 'settings_vibration';

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true;
    _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
    if (value) hapticMedium();
  }

  void hapticLight() => _haptic(HapticFeedback.lightImpact);
  void hapticMedium() => _haptic(HapticFeedback.mediumImpact);

  void _haptic(Future<void> Function() fn) {
    if (!_vibrationEnabled) return;
    try {
      fn();
    } catch (_) {
      // Haptics are optional; never break a tap.
    }
  }
}
