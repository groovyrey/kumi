class AppConfig {
  AppConfig._();

  static const tmdbApiKey = '3fd2be6f0c70a2a598f084ddfb75487c';
  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const tmdbImageBase = 'https://image.tmdb.org/t/p/w500';

  /// Temporary diagnostic: shows the surviving ad-layer overlays inside the
  /// player so the guard can be tuned precisely. Remove once CineSrc is final.
  static const bool kDebugAdAudit = true;
}

class EmbedSources {
  EmbedSources._();

  static final List<
      (String name, String Function({required int id, required String media}))>
      sources = [
    ('CineSrc', ({required id, required media}) =>
        'https://cinesrc.st/embed/${media == 'tvplay' ? 'tv' : 'movie'}/$id'),
  ];
}
