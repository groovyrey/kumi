import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item.dart';

/// A title the user opened for playback, newest first.
class WatchEntry {
  const WatchEntry({required this.item, required this.watchedAt});

  final MediaItem item;
  final int watchedAt;

  Map<String, dynamic> toJson() => {
        'id': item.id,
        'title': item.title,
        'overview': item.overview,
        'poster_path': item.posterPath,
        'backdrop_path': item.backdropPath,
        'rating': item.rating,
        'release_date': item.releaseDate,
        'genre_ids': item.genreIds,
        'media_type': item.mediaType,
        'watched_at': watchedAt,
      };

  static WatchEntry? fromJson(Map<String, dynamic> json) {
    final mediaType = json['media_type'] as String? ?? '';
    if (mediaType != 'movie' && mediaType != 'tv') return null;
    return WatchEntry(
      item: MediaItem(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? 'Untitled',
        overview: json['overview'] as String? ?? '',
        posterPath: json['poster_path'] as String? ?? '',
        backdropPath: json['backdrop_path'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        releaseDate: json['release_date'] as String? ?? '',
        genreIds: (json['genre_ids'] as List?)?.cast<int>() ?? const [],
        mediaType: mediaType,
      ),
      watchedAt: json['watched_at'] as int? ?? 0,
    );
  }
}

/// Tracks recently played titles so the app can offer Continue Watching.
///
/// A ChangeNotifier so the Home screen can rebuild instantly when a title is
/// recorded — including when the recording happens on another route.
class WatchHistory extends ChangeNotifier {
  WatchHistory._();
  static final WatchHistory instance = WatchHistory._();

  static const _key = 'watch_history';
  static const _limit = 30;

  List<WatchEntry> _entries = [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _entries = _decode(prefs.getString(_key) ?? '');
    } catch (_) {
      _entries = [];
    }
    _loaded = true;
    notifyListeners();
  }

  List<WatchEntry> get entries => List.unmodifiable(_entries);

  Future<void> record(MediaItem item) async {
    await ensureLoaded();
    _entries.removeWhere(
      (e) => e.item.id == item.id && e.item.mediaType == item.mediaType,
    );
    _entries.insert(
      0,
      WatchEntry(
        item: item,
        watchedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (_entries.length > _limit) {
      _entries.removeRange(_limit, _entries.length);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    await ensureLoaded();
    _entries.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Best-effort persistence.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode([for (final e in _entries) e.toJson()]),
      );
    } catch (_) {
      // Best-effort persistence.
    }
  }

  List<WatchEntry> _decode(String raw) {
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((e) => WatchEntry.fromJson((e as Map).cast<String, dynamic>()))
          .whereType<WatchEntry>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}