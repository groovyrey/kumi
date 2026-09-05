import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class AppState extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _accentKey = 'accent_color';

  ThemeMode _themeMode = ThemeMode.system;
  AccentOption _accent = AccentOption.ocean;

  ThemeMode get themeMode => _themeMode;

  AccentOption get accent => _accent;

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
      orElse: () => AccentOption.ocean,
    );
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
}