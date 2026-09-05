import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/genre.dart';
import '../models/media_item.dart';
import '../models/series_details.dart';

/// A single TMDB page of results plus paging metadata for incremental loads.
class MediaPage {
  const MediaPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<MediaItem> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  static const empty = MediaPage(items: [], page: 0, totalPages: 0);
}

class TmdbService {
  TmdbService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _media = 'movie';
  static const _tv = 'tv';

  Uri _uri(String path, {Map<String, String>? query}) {
    return Uri.parse('${AppConfig.tmdbBaseUrl}$path').replace(
      queryParameters: {
        'api_key': AppConfig.tmdbApiKey,
        'language': 'en-US',
        for (final e in (query ?? {}).entries) e.key: e.value,
      },
    );
  }

  Future<MediaPage> _fetchPage(
    String path,
    String mediaType, {
    int page = 1,
    Map<String, String>? query,
  }) async {
    final res = await _client.get(_uri(
      path,
      query: {
        'page': '$page',
        for (final e in (query ?? {}).entries) e.key: e.value,
      },
    ));
    if (res.statusCode != 200) {
      throw Exception('TMDB request failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List? ?? const [];
    final items = results
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>, mediaType))
        .toList();
    return MediaPage(
      items: items,
      page: data['page'] as int? ?? page,
      totalPages: data['total_pages'] as int? ?? page,
    );
  }

  Future<MediaPage> popularMoviesPage({int page = 1}) =>
      _fetchPage('/$_media/popular', _media, page: page);

  Future<MediaPage> nowPlayingMoviesPage({int page = 1}) =>
      _fetchPage('/$_media/now_playing', _media, page: page);

  Future<MediaPage> upcomingMoviesPage({int page = 1}) =>
      _fetchPage('/$_media/upcoming', _media, page: page);

  Future<MediaPage> topRatedMoviesPage({int page = 1}) =>
      _fetchPage('/$_media/top_rated', _media, page: page);

  Future<MediaPage> popularSeriesPage({int page = 1}) =>
      _fetchPage('/$_tv/popular', _tv, page: page);

  Future<MediaPage> onTheAirSeriesPage({int page = 1}) =>
      _fetchPage('/$_tv/on_the_air', _tv, page: page);

  /// Details for a series, including the next scheduled episode if any.
  Future<SeriesDetails?> seriesDetails(int id) async {
    final res = await _client.get(_uri('/$_tv/$id'));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SeriesDetails.fromJson(data);
  }

  Future<MediaPage> searchPage(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return MediaPage.empty;
    final movies = await _fetchPage(
      '/search/$_media',
      _media,
      page: page,
      query: {'query': query},
    );
    final series = await _fetchPage(
      '/search/$_tv',
      _tv,
      page: page,
      query: {'query': query},
    );
    final total = movies.totalPages > series.totalPages
        ? movies.totalPages
        : series.totalPages;
    return MediaPage(
      items: [...movies.items, ...series.items],
      page: page,
      totalPages: total,
    );
  }

  /// The TMDB movie genre list for the category dropdown.
  Future<List<Genre>> movieGenres() async {
    final res = await _client.get(_uri('/genre/$_media/list'));
    if (res.statusCode != 200) {
      throw Exception('TMDB genres failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['genres'] as List? ?? const [];
    return list
        .map((e) => Genre.fromJson(e as Map<String, dynamic>))
        .where((g) => g.name.isNotEmpty)
        .toList();
  }

  /// Movies inside a genre, using the TMDB discover endpoint.
  Future<MediaPage> genreMoviesPage(int genreId, {int page = 1}) =>
      _fetchPage(
        '/discover/$_media',
        _media,
        page: page,
        query: {'with_genres': '$genreId'},
      );

  // ── First-page shortcuts used by one-shot callers ────────────────────

  Future<List<MediaItem>> popularMovies() async =>
      (await popularMoviesPage()).items;

  Future<List<MediaItem>> nowPlayingMovies() async =>
      (await nowPlayingMoviesPage()).items;

  Future<List<MediaItem>> upcomingMovies() async =>
      (await upcomingMoviesPage()).items;

  Future<List<MediaItem>> popularSeries() async =>
      (await popularSeriesPage()).items;

  Future<List<MediaItem>> trendingSeries() async =>
      (await onTheAirSeriesPage()).items;

  Future<List<MediaItem>> search(String query) async =>
      (await searchPage(query)).items;
}