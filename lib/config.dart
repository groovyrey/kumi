class AppConfig {
  AppConfig._();

  static const tmdbApiKey = '3fd2be6f0c70a2a598f084ddfb75487c';
  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const tmdbImageBase = 'https://image.tmdb.org/t/p/w500';

  /// Resolver/proxy worker that returns native playable (MP4 / HLS) URLs for
  /// the direct-file providers. See worker8652 `/api/kumi/resolve`.
  static const resolverBase = 'https://worker8652.appleflux.workers.dev/api/kumi';
}

/// Native direct-file sources. These resolve to a playable MP4 or proxied HLS
/// URL through the resolver worker and are played with the platform video
/// player (`video_player`) — no WebView, no in-page ads.
class NativeSources {
  NativeSources._();

  static const providerNames = ['vidlink', 'vidlove'];
  static const providerLabels = {'vidlink': 'VidLink', 'vidlove': '111Movies'};

  static List<({String name, String label})> get providers =>
      [for (final n in providerNames) (name: n, label: providerLabels[n]!)];
}

/// Embed/web sources. These are played inside the WebView with the ad layer
/// stripped by `EmbedAdGuard`; used as a fallback when no native source
/// resolves for a title.
class EmbedSources {
  EmbedSources._();

  static final List<
      (String name, String Function({required int id, required String media}))>
      sources = [
    ('CineSrc', ({required id, required media}) =>
        'https://cinesrc.st/embed/${media == 'tvplay' ? 'tv' : 'movie'}/$id'),
  ];
}