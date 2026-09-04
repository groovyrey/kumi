import 'package:kumi/config.dart';

class MediaItem {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String? backdropPath;
  final double rating;
  final String releaseDate;
  final List<int> genreIds;
  final String mediaType;

  const MediaItem({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    this.backdropPath,
    required this.rating,
    required this.releaseDate,
    required this.genreIds,
    required this.mediaType,
  });

  String get posterUrl {
    final p = posterPath;
    return p.isEmpty ? '' : '${AppConfig.tmdbImageBase}$p';
  }

  factory MediaItem.fromJson(Map<String, dynamic> json, String mediaType) {
    return MediaItem(
      id: json['id'] as int? ?? 0,
      title: (json['title'] as String?) ??
          (json['name'] as String?) ??
          'Untitled',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String? ?? '',
      backdropPath: json['backdrop_path'] as String?,
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
      releaseDate: (json['release_date'] as String?) ??
          (json['first_air_date'] as String?) ??
          '',
      genreIds: (json['genre_ids'] as List?)?.cast<int>() ?? const [],
      mediaType: mediaType,
    );
  }
}
