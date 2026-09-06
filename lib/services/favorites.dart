import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item.dart';

/// A saved title on the user's list, newest first.
class FavoriteEntry {
  const FavoriteEntry({required this.item, required this.addedAt});

  final MediaItem item;
  final int addedAt;

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
        'added_at': addedAt,
      };

  static FavoriteEntry? fromJson(Map<String, dynamic> json) {
    final mediaType = json['media_type'] as String? ?? '';
    if (mediaType != 'movie' && mediaType != 'tv') return null;
    return FavoriteEntry(
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
      addedAt: json['added_at'] as int? ?? 0,
    );
  }
}

/// The user's saved titles ("My List"), persisted locally.
///
/// A ChangeNotifier so any screen toggling a heart under another route can
/// rebuild instantly wherever the list is shown.
class Favorites extends ChangeNotifier {
  Favorites._();
  static final Favorites instance = Favorites._();

  static const _key = 'favorites';
  static const _limit = 200;

  final List<FavoriteEntry> _entries = [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _entries.addAll(_decode(prefs.getString(_key) ?? ''));
    } catch (_) {
      // Nothing to load.
    }
    _loaded = true;
    notifyListeners();
  }

  List<MediaItem> get items => List.unmodifiable([for (final e in _entries) e.item]);

  bool contains(MediaItem item) =>
      _contains(item.mediaType, item.id);

  bool _contains(String mediaType, int id) {
    for (final e in _entries) {
      if (e.item.mediaType == mediaType && e.item.id == id) return true;
    }
    return false;
  }

  Future<void> toggle(MediaItem item) async {
    await ensureLoaded();
    final index = _entries.indexWhere(
      (e) => e.item.mediaType == item.mediaType && e.item.id == item.id,
    );
    if (index >= 0) {
      _entries.removeAt(index);
    } else {
      _entries.insert(
        0,
        FavoriteEntry(
          item: item,
          addedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
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
        jsonEncode([for (final e in _entries.take(_limit)) e.toJson()]),
      );
    } catch (_) {
      // Best-effort persistence.
    }
  }

  List<FavoriteEntry> _decode(String raw) {
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((e) => FavoriteEntry.fromJson((e as Map).cast<String, dynamic>()))
          .whereType<FavoriteEntry>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}