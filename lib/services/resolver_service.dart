import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// A subtitle track attached to a resolved native source (VidLink captions).
class SubtitleInfo {
  const SubtitleInfo({
    required this.url,
    required this.label,
    required this.type,
  });

  final String url;
  final String label;
  final String type;

  static SubtitleInfo? tryFromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final url = data['url'];
    if (url is! String || url.isEmpty) return null;
    return SubtitleInfo(
      url: url,
      label: data['label'] as String? ?? 'Subtitle',
      type: data['type'] as String? ?? 'srt',
    );
  }
}

/// A resolved native playback URL from the Kumi resolver worker.
class ResolvedSource {
  const ResolvedSource({
    required this.playUrl,
    required this.quality,
    required this.provider,
    this.subtitles = const [],
  });

  final String playUrl;
  final String quality;
  final String provider;

  /// Optional external subtitle tracks for this source (e.g. VidLink
  /// captions). Empty when the provider exposes none.
  final List<SubtitleInfo> subtitles;

  static ResolvedSource? tryFromJson(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    if (data['ok'] != true) return null;
    final playUrl = data['playUrl'];
    if (playUrl is! String || playUrl.isEmpty) return null;
    final rawSubtitles = data['subtitles'];
    final subtitles = rawSubtitles is List
        ? [
            for (final item in rawSubtitles)
              if (SubtitleInfo.tryFromJson(item) case final subtitle?)
                subtitle,
          ]
        : const <SubtitleInfo>[];
    return ResolvedSource(
      playUrl: playUrl,
      quality: data['quality'] as String? ?? 'auto',
      provider: data['provider'] as String? ?? 'native',
      subtitles: subtitles,
    );
  }
}

class ResolveFailure implements Exception {
  const ResolveFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Talks to the Kumi resolver worker, which turns TMDB ids into native
/// playable MP4 / proxied-HLS URLs for [NativeSources.providerNames].
class ResolverService {
  ResolverService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Resolves a playable URL for [provider] ('vidlink' | 'vidlove').
  ///
  /// [type] is 'movie' or 'tv'; [season]/[episode] are required for tv.
  /// Throws [ResolveFailure] when the provider has nothing for this title.
  Future<ResolvedSource> resolve({
    required String provider,
    required String type,
    required int id,
    int season = 1,
    int episode = 1,
  }) async {
    final uri = Uri.parse('${AppConfig.resolverBase}/resolve').replace(
      queryParameters: {
        'provider': provider,
        'type': type,
        'id': '$id',
        if (type == 'tv') 'season': '$season',
        if (type == 'tv') 'episode': '$episode',
      },
    );
    final http.Response res;
    try {
      res = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const ResolveFailure('Failed to reach the resolver.');
    }
    if (res.statusCode != 200) {
      throw ResolveFailure('Resolver error ${res.statusCode}.');
    }
    final data = jsonDecode(res.body);
    final source = ResolvedSource.tryFromJson(data);
    if (source == null) {
      final message = data is Map<String, dynamic>
          ? (data['error'] as String?) ?? 'Nothing playable.'
          : 'Nothing playable.';
      throw ResolveFailure(message);
    }
    return source;
  }
}