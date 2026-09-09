import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../theme/app_theme.dart';

/// Playback engine: native first with an embed fallback, or embeds only.
enum PlaybackEngine { native, embed }

/// When the on-screen player controls auto-hide.
enum ControlsTimeout { short, long, never }

/// Preferred playback quality handed to the resolver worker.
enum QualityPreference {
  auto('Auto', 'auto'),
  p2160('2160p', '2160'),
  p1080('1080p', '1080'),
  p720('720p', '720'),
  p480('480p', '480');

  const QualityPreference(this.label, this.value);
  final String label;

  /// Value sent to the worker (matches the provider's tier keys).
  final String value;
}

/// Which native direct-file provider to try first.
enum SourceOrder { auto('Auto'), vidlink('VidLink'), vidlove('111Movies') }

/// Which release channel the update banner listens to.
enum UpdateChannel { stable('Stable'), beta('Beta') }

class AppState extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _accentKey = 'accent_color';
  static const _engineKey = 'playback_engine';
  static const _hardwareDecodeKey = 'hardware_decode';
  static const _defaultSpeedKey = 'default_speed';
  static const _preferredSubtitleKey = 'preferred_subtitle';
  static const _controlsTimeoutKey = 'controls_timeout';
  static const _qualityKey = 'preferred_quality';
  static const _sourceOrderKey = 'source_order';
  static const _updateChannelKey = 'update_channel';
  static const _autoCheckKey = 'auto_check_updates';
  static const _keepAwakeKey = 'keep_screen_awake';
  static const _resolverOverrideKey = 'resolver_base_override';

  static const _settingsKeys = [
    _themeModeKey,
    _accentKey,
    _engineKey,
    _hardwareDecodeKey,
    _defaultSpeedKey,
    _preferredSubtitleKey,
    _controlsTimeoutKey,
    _qualityKey,
    _sourceOrderKey,
    _updateChannelKey,
    _autoCheckKey,
    _keepAwakeKey,
    _resolverOverrideKey,
  ];

  ThemeMode _themeMode = ThemeMode.system;
  AccentOption _accent = AccentOption.crimson;
  PlaybackEngine _engine = PlaybackEngine.native;
  bool _hardwareDecode = false;
  double _defaultSpeed = 1.0;
  String _preferredSubtitle = '';
  ControlsTimeout _controlsTimeout = ControlsTimeout.short;
  QualityPreference _quality = QualityPreference.auto;
  SourceOrder _sourceOrder = SourceOrder.auto;
  UpdateChannel _updateChannel = UpdateChannel.stable;
  bool _autoCheckUpdates = true;
  bool _keepAwake = true;
  String _resolverOverride = '';

  ThemeMode get themeMode => _themeMode;
  AccentOption get accent => _accent;
  PlaybackEngine get engine => _engine;
  bool get hardwareDecode => _hardwareDecode;
  double get defaultSpeed => _defaultSpeed;
  String get preferredSubtitle => _preferredSubtitle;
  ControlsTimeout get controlsTimeout => _controlsTimeout;
  QualityPreference get quality => _quality;
  SourceOrder get sourceOrder => _sourceOrder;
  UpdateChannel get updateChannel => _updateChannel;
  bool get autoCheckUpdates => _autoCheckUpdates;
  bool get keepAwake => _keepAwake;
  String get resolverOverride => _resolverOverride;

  int get themeModeIndex => switch (themeMode) {
        ThemeMode.light => 0,
        ThemeMode.dark => 1,
        ThemeMode.system => 2,
      };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = switch (prefs.getString(_themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _accent = AccentOption.values.firstWhere(
      (option) => option.name == prefs.getString(_accentKey),
      orElse: () => AccentOption.crimson,
    );
    _engine = switch (prefs.getString(_engineKey)) {
      'embed' => PlaybackEngine.embed,
      _ => PlaybackEngine.native,
    };
    _hardwareDecode = prefs.getBool(_hardwareDecodeKey) ?? false;
    _defaultSpeed =
        prefs.getDouble(_defaultSpeedKey)?.clamp(0.5, 2.0) ?? 1.0;
    _preferredSubtitle = prefs.getString(_preferredSubtitleKey) ?? '';
    _controlsTimeout = switch (prefs.getString(_controlsTimeoutKey)) {
      'long' => ControlsTimeout.long,
      'never' => ControlsTimeout.never,
      _ => ControlsTimeout.short,
    };
    _quality = QualityPreference.values.firstWhere(
      (value) => value.name == prefs.getString(_qualityKey),
      orElse: () => QualityPreference.auto,
    );
    _sourceOrder = SourceOrder.values.firstWhere(
      (value) => value.name == prefs.getString(_sourceOrderKey),
      orElse: () => SourceOrder.auto,
    );
    _updateChannel = UpdateChannel.values.firstWhere(
      (value) => value.name == prefs.getString(_updateChannelKey),
      orElse: () => UpdateChannel.stable,
    );
    _autoCheckUpdates = prefs.getBool(_autoCheckKey) ?? true;
    _keepAwake = prefs.getBool(_keepAwakeKey) ?? true;
    _resolverOverride = prefs.getString(_resolverOverrideKey) ?? '';
    AppConfig.resolverBaseOverride = _resolverOverride;
    notifyListeners();
  }

  Future<void> cycleTheme() async {
    final next = switch (themeMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    _themeMode = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, next.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setAccent(AccentOption option) async {
    _accent = option;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentKey, option.name);
  }

  Future<void> setEngine(PlaybackEngine engine) async {
    _engine = engine;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_engineKey, engine.name);
  }

  Future<void> setHardwareDecode(bool enabled) async {
    _hardwareDecode = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hardwareDecodeKey, enabled);
  }

  Future<void> setDefaultSpeed(double speed) async {
    _defaultSpeed = speed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_defaultSpeedKey, speed);
  }

  Future<void> setPreferredSubtitle(String language) async {
    _preferredSubtitle = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredSubtitleKey, language);
  }

  Future<void> setControlsTimeout(ControlsTimeout value) async {
    _controlsTimeout = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_controlsTimeoutKey, value.name);
  }

  Future<void> setQuality(QualityPreference value) async {
    _quality = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_qualityKey, value.name);
  }

  Future<void> setSourceOrder(SourceOrder value) async {
    _sourceOrder = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sourceOrderKey, value.name);
  }

  Future<void> setUpdateChannel(UpdateChannel value) async {
    _updateChannel = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_updateChannelKey, value.name);
  }

  Future<void> setAutoCheckUpdates(bool enabled) async {
    _autoCheckUpdates = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCheckKey, enabled);
  }

  Future<void> setKeepAwake(bool enabled) async {
    _keepAwake = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepAwakeKey, enabled);
  }

  Future<void> setResolverOverride(String value) async {
    _resolverOverride = value.trim();
    AppConfig.resolverBaseOverride = _resolverOverride;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resolverOverrideKey, _resolverOverride);
  }

  /// Clears every setting back to its default. History, favorites and update
  /// cache are left untouched; point to the App about screen / watch history
  /// for those.
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _settingsKeys) {
      await prefs.remove(key);
    }
    _themeMode = ThemeMode.system;
    _accent = AccentOption.crimson;
    _engine = PlaybackEngine.native;
    _hardwareDecode = false;
    _defaultSpeed = 1.0;
    _preferredSubtitle = '';
    _controlsTimeout = ControlsTimeout.short;
    _quality = QualityPreference.auto;
    _sourceOrder = SourceOrder.auto;
    _updateChannel = UpdateChannel.stable;
    _autoCheckUpdates = true;
    _keepAwake = true;
    _resolverOverride = '';
    AppConfig.resolverBaseOverride = '';
    notifyListeners();
  }
}