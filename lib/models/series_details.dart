/// Scheduled airing info pulled from the TMDB tv details endpoint.
///
/// TMDB does not predict upcoming airdates; it lists the episodes broadcast
/// schedules already contain. `nextEpisodeToAir` is only present while a show
/// has a scheduled future episode.
class SeriesDetails {
  const SeriesDetails({this.nextEpisodeToAir, this.lastEpisodeToAir});

  final EpisodeAir? nextEpisodeToAir;
  final EpisodeAir? lastEpisodeToAir;

  factory SeriesDetails.fromJson(Map<String, dynamic> json) {
    return SeriesDetails(
      nextEpisodeToAir: _episode(json['next_episode_to_air']),
      lastEpisodeToAir: _episode(json['last_episode_to_air']),
    );
  }

  static EpisodeAir? _episode(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final date = raw['air_date'];
    if (date is! String || date.isEmpty) return null;
    final name = raw['name'];
    final season = raw['season_number'];
    final episode = raw['episode_number'];
    return EpisodeAir(
      airDate: date,
      season: season is int ? season : null,
      episode: episode is int ? episode : null,
      name: name is String ? name : '',
    );
  }
}

class EpisodeAir {
  const EpisodeAir({
    required this.airDate,
    required this.season,
    required this.episode,
    required this.name,
  });

  /// ISO-8601 date, e.g. "2026-03-05".
  final String airDate;
  final int? season;
  final int? episode;
  final String name;
}