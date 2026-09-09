import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item.dart';

/// A title the user opened for playback, newest first. For series, [season]
/// and [episode] remember where they last started. [positionSeconds] tracks
/// the playback position of that title/episode so playback can resume where
/// the user left off; it is cleared when the video reaches its end.
class WatchEntry {
  const WatchEntry({
    required this.item,
    required this.watchedAt,
    this.season,
    this.episode,
    this.positionSeconds,
  });

  final MediaItem item;
  final int watchedAt;
  final int? season;
  final int? episode;
  final int? positionSeconds;

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
        if (season != null) 'season': season,
        if (episode != null) 'episode': episode,
        if (positionSeconds != null) 'position_seconds': positionSeconds,
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
      season: json['season'] as int?,
      episode: json['episode'] as int?,
      positionSeconds: json['position_seconds'] as int?,
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

  Future<void> record(
    MediaItem item, {
    int? season,
    int? episode,
  }) async {
    await ensureLoaded();
    final previous = _entries
        .where((e) => e.item.id == item.id && e.item.mediaType == item.mediaType)
        .firstOrNull;
    final sameSpot = previous != null &&
        previous.season == season &&
        previous.episode == episode;
    _entries.removeWhere(
      (e) => e.item.id == item.id && e.item.mediaType == item.mediaType,
    );
    _entries.insert(
      0,
      WatchEntry(
        item: item,
        watchedAt: DateTime.now().millisecondsSinceEpoch,
        season: season,
        episode: episode,
        // Re-starting the exact same title/episode keeps its saved position
        // so playback resumes; a different episode starts from zero.
        positionSeconds: sameSpot ? previous.positionSeconds : null,
      ),
    );
    if (_entries.length > _limit) {
      _entries.removeRange(_limit, _entries.length);
    }
    notifyListeners();
    await _persist();
  }

  /// The saved position for [id]/[mediaType], but only when it refers to the
  /// exact season and episode the caller is about to play. Movies return
  /// their position when no season/episode is given.
  Duration? resumePosition(
    int id,
    String mediaType, {
    int? season,
    int? episode,
  }) {
    int? seconds;
    for (final e in _entries) {
      if (e.item.id != id || e.item.mediaType != mediaType) continue;
      if (mediaType == 'tv') {
        if (e.season != season || e.episode != episode) return null;
      } else if (e.season != null) {
        return null;
      }
      seconds = e.positionSeconds;
      break;
    }
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds);
  }

  /// Updates the saved position for the matching title/episode. The entry is
  /// created by [record] when playback starts, so this only mutates it.
  Future<void> updateProgress(
    int id,
    String mediaType, {
    int? season,
    int? episode,
    required Duration position,
  }) async {
    await ensureLoaded();
    var changed = false;
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.item.id != id || e.item.mediaType != mediaType) continue;
      final sameSpot = mediaType == 'movie'
          ? e.season == null
          : (e.season == season && e.episode == episode);
      if (!sameSpot) return;
      _entries[i] = WatchEntry(
        item: e.item,
        watchedAt: e.watchedAt,
        season: e.season,
        episode: e.episode,
        positionSeconds: position.inSeconds,
      );
      changed = true;
      break;
    }
    if (!changed) return;
    notifyListeners();
    await _persist();
  }

  /// Discards the saved position so the title starts over next time.
  Future<void> clearProgress(
    int id,
    String mediaType, {
    int? season,
    int? episode,
  }) async {
    await ensureLoaded();
    var changed = false;
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.item.id != id || e.item.mediaType != mediaType) continue;
      if (mediaType == 'tv' &&
          (e.season != season || e.episode != episode)) {
        return;
      }
      _entries[i] = WatchEntry(
        item: e.item,
        watchedAt: e.watchedAt,
        season: e.season,
        episode: e.episode,
        positionSeconds: null,
      );
      changed = true;
      break;
    }
    if (!changed) return;
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

  Future<void> remove(WatchEntry entry) async {
    await ensureLoaded();
    final before = _entries.length;
    _entries.removeWhere(
      (e) =>
          e.item.id == entry.item.id &&
          e.item.mediaType == entry.item.mediaType,
    );
    if (_entries.length == before) return;
    notifyListeners();
    await _persist();
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