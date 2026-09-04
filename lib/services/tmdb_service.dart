import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/media_item.dart';

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

  Future<List<MediaItem>> _fetchList(
    String path,
    String mediaType, {
    Map<String, String>? query,
  }) async {
    final res = await _client.get(_uri(path, query: query));
    if (res.statusCode != 200) {
      throw Exception('TMDB request failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List? ?? const [];
    return results
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>, mediaType))
        .toList();
  }

  Future<List<MediaItem>> popularMovies() =>
      _fetchList('/$_media/popular', _media);

  Future<List<MediaItem>> nowPlayingMovies() =>
      _fetchList('/$_media/now_playing', _media);

  Future<List<MediaItem>> upcomingMovies() =>
      _fetchList('/$_media/upcoming', _media);

  Future<List<MediaItem>> popularSeries() => _fetchList('/$_tv/popular', _tv);

  Future<List<MediaItem>> trendingSeries() =>
      _fetchList('/$_tv/on_the_air', _tv);

  Future<List<MediaItem>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    final movies = await _fetchList(
      '/search/$_media',
      _media,
      query: {'query': query, 'page': '1'},
    );
    final series = await _fetchList(
      '/search/$_tv',
      _tv,
      query: {'query': query, 'page': '1'},
    );
    return [...movies, ...series];
  }
}
