/// A single episode of a TV show, as returned by the TMDB season endpoint.
class TvEpisode {
  const TvEpisode({
    required this.number,
    required this.name,
    required this.overview,
    required this.airDate,
    required this.rating,
    required this.stillPath,
  });

  final int number;
  final String name;
  final String overview;
  final String airDate;
  final double rating;
  final String stillPath;

  factory TvEpisode.fromJson(Map<String, dynamic> json) {
    return TvEpisode(
      number: json['episode_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Episode',
      overview: json['overview'] as String? ?? '',
      airDate: json['air_date'] as String? ?? '',
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
      stillPath: json['still_path'] as String? ?? '',
    );
  }
}

/// A season with its episodes, built from the TMDB show + season endpoints.
class TvSeason {
  const TvSeason({
    required this.number,
    required this.name,
    required this.episodes,
  });

  final int number;
  final String name;
  final List<TvEpisode> episodes;

  factory TvSeason.fromJson(Map<String, dynamic> json) {
    final rawEpisodes = json['episodes'] as List? ?? const [];
    return TvSeason(
      number: json['season_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Season',
      episodes: [
        for (final e in rawEpisodes)
          if (e is Map)
            TvEpisode.fromJson((e as Map).cast<String, dynamic>()),
      ],
    );
  }
}