import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks how long the app spends in the foreground each day and how that time
/// splits across sections, powering the personal screen-time metrics on Home.
///
/// Time is accumulated whenever the app is brought back to the foreground or
/// the active section changes, and is persisted best-effort to preferences.
/// All reads go through the singleton, so Home can rebuild via notifications.
class ScreenTime extends ChangeNotifier {
  ScreenTime._();
  static final ScreenTime instance = ScreenTime._();

  static const _key = 'screen_time_v1';

  Map<String, int> _dailies = {};
  String _dayKey = _keyOf(DateTime.now());
  int _todaySeconds = 0;
  Map<String, int> _sections = {};
  bool _loaded = false;

  bool _active = false;
  String? _currentSection;
  DateTime _lastMark = DateTime.now();

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _dailies = (data['daily'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt()));
        final day = data['day'] as Map<String, dynamic>? ?? {};
        _dayKey = day['date'] as String? ?? _dayKey;
        _sections = (day['sections'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt()));
        if (_dayKey == _keyOf(DateTime.now())) {
          _todaySeconds = (day['seconds'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (_) {
      _dailies = {};
      _sections = {};
      _todaySeconds = 0;
    }
    _prune();
    _loaded = true;
    notifyListeners();
  }

  static String _keyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  int get todaySeconds => _todaySeconds;

  /// Seconds spent in each section today, label -> seconds.
  Map<String, int> get sections => Map.unmodifiable(_sections);

  /// Last 7 days, oldest first, ending today. Missing days count as zero.
  List<(DateTime, int)> get last7 {
    final now = DateTime.now();
    final out = <(DateTime, int)>[];
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = _keyOf(day);
      out.add((day, key == _dayKey ? _todaySeconds : _dailies[key] ?? 0));
    }
    return out;
  }

  /// Whether the app is foregrounded and should count time.
  void setActive(bool active) {
    _active = active;
    if (active) {
      _lastMark = DateTime.now();
    } else {
      _accumulate();
      _persist();
    }
  }

  /// Marks the currently focused section; elapsed time since the previous
  /// mark (or resume) is attributed to the previous section.
  void switchSection(String label) {
    _accumulate();
    _currentSection = label;
  }

  void _accumulate() {
    final now = DateTime.now();
    final key = _keyOf(now);
    if (key != _dayKey) {
      _dailies[_dayKey] = _todaySeconds;
      _dayKey = key;
      _todaySeconds = 0;
      _sections = {};
      _prune();
      if (_currentSection != null) _sections[_currentSection!] = 0;
    }
    final elapsed = now.difference(_lastMark);
    _lastMark = now;
    if (!_active || elapsed.inSeconds <= 0) return;
    _todaySeconds += elapsed.inSeconds;
    _sections[_currentSection ?? 'Home'] =
        (_sections[_currentSection ?? 'Home'] ?? 0) + elapsed.inSeconds;
    notifyListeners();
  }

  void _prune() {
    final keys = _dailies.keys.toList()..sort();
    while (keys.length > 31) {
      _dailies.remove(keys.removeAt(0));
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'daily': _dailies,
          'day': {
            'date': _dayKey,
            'seconds': _todaySeconds,
            'sections': _sections,
          },
        }),
      );
    } catch (_) {
      // Best-effort persistence.
    }
  }
}