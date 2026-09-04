class AppConfig {
  AppConfig._();

  static const tmdbApiKey = '3fd2be6f0c70a2a598f084ddfb75487c';
  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const tmdbImageBase = 'https://image.tmdb.org/t/p/w500';
}

class EmbedSources {
  EmbedSources._();

  static final List<
      (String name, String Function({required int id, required String media}))>
      sources = [
    ('CineSrc', ({required id, required media}) =>
        'https://cinesrc.st/embed/${media == 'tvplay' ? 'tv' : 'movie'}/$id'),
    ('PlayAPI', ({required id, required media}) =>
        'https://player.playapi.eu.cc/?id=$id&type=$media'),
    ('Peachify', ({required id, required media}) =>
        'https://peachify.top/embed/${media == 'tvplay' ? 'tv' : 'movie'}/$id'),
    ('VidGod', ({required id, required media}) =>
        'https://vidgod.net/${media == 'tvplay' ? 'tv' : 'movie'}/$id'),
  ];
}
