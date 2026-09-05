import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Details about a newer release found on GitHub.
class VersionInfo {
  const VersionInfo({required this.version, required this.url});

  final String version;
  final String url;
}

/// Checks the installed Kumi version against the latest GitHub release.
///
/// The result is cached for a day so the API is only hit once per day per
/// installed version; an upgrade it already announced stays visible from the
/// cache. Any failure quietly results in "no update" — the banner must never
/// break browsing.
class VersionChecker {
  VersionChecker({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _tagUrl =
      'https://api.github.com/repos/groovyrey/kumi/releases/latest';
  static const _cacheWindow = Duration(hours: 24);
  static const _cachedVersionKey = 'cached_latest_version';
  static const _cachedCheckKey = 'last_version_check';
  static const _cachedInstalledKey = 'cached_checked_installed';

  /// Returns a newer release than the installed app, or null when Kumi is up
  /// to date (or the check can't be made).
  Future<VersionInfo?> check() async {
    final prefs = await SharedPreferences.getInstance();
    final installed = await _installedVersion();

    try {
      final cached = prefs.getString(_cachedVersionKey);
      final cachedInstalled = prefs.getString(_cachedInstalledKey);
      final lastCheck = prefs.getInt(_cachedCheckKey) ?? 0;
      final withinWindow =
          DateTime.now().millisecondsSinceEpoch - lastCheck <
              _cacheWindow.inMilliseconds;

      if (cached != null &&
          cachedInstalled == installed &&
          withinWindow &&
          !_isNewer(cached, installed)) {
        return null;
      }

      final res = await _client
          .get(Uri.parse(_tagUrl), headers: const {'User-Agent': 'kumi'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String?) ?? '';
      final version = tag.startsWith('v') ? tag.substring(1) : tag;
      final url = data['html_url'] as String? ?? '';
      if (version.isEmpty || url.isEmpty) return null;

      await prefs.setInt(
          _cachedCheckKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(_cachedVersionKey, version);
      await prefs.setString(_cachedInstalledKey, installed);

      if (!_isNewer(version, installed)) return null;
      return VersionInfo(version: version, url: url);
    } catch (_) {
      return null;
    }
  }

  Future<String> _installedVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '';
    }
  }

  // Compares "major.minor.patch" version strings; later wins.
  bool _isNewer(String candidate, String current) {
    final a = _parts(candidate);
    final b = _parts(current);
    if (a.length != 3 || b.length != 3) return false;
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  List<int> _parts(String value) {
    return value
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}