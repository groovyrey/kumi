/// A TMDB genre (e.g. Action, Drama, Sci-Fi) used to filter discovery.
class Genre {
  const Genre({required this.id, required this.name});

  final int id;
  final String name;

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }

  /// Covers familiar movie genres in case the genre list request fails
  /// (offline or a newer TMDB structure) so the filter still works.
  static const common = <Genre>[
    Genre(id: 28, name: 'Action'),
    Genre(id: 12, name: 'Adventure'),
    Genre(id: 16, name: 'Animation'),
    Genre(id: 35, name: 'Comedy'),
    Genre(id: 80, name: 'Crime'),
    Genre(id: 99, name: 'Documentary'),
    Genre(id: 18, name: 'Drama'),
    Genre(id: 10751, name: 'Family'),
    Genre(id: 14, name: 'Fantasy'),
    Genre(id: 27, name: 'Horror'),
    Genre(id: 9648, name: 'Mystery'),
    Genre(id: 10749, name: 'Romance'),
    Genre(id: 878, name: 'Sci-Fi'),
    Genre(id: 53, name: 'Thriller'),
  ];
}