class Movie {
  final int id;
  final String title;
  final List<String> genre;
  final int year;
  final String description;
  final String? trailerUrl;
  final String posterUrl;
  final List<String> cast;
  final String director;

  Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.description,
    this.trailerUrl,
    required this.posterUrl,
    required this.cast,
    required this.director,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      genre: List<String>.from(json['genre'] ?? []),
      year: json['year'] ?? 0,
      description: json['description'] ?? '',
      trailerUrl:
          json['trailer_url']?.isNotEmpty == true ? json['trailer_url'] : null,
      posterUrl: json['poster_url'] ?? '',
      cast: List<String>.from(json['cast'] ?? []),
      director: json['director'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'genre': genre,
      'year': year,
      'description': description,
      'trailer_url': trailerUrl,
      'poster_url': posterUrl,
      'cast': cast,
      'director': director,
    };
  }

  @override
  String toString() {
    return 'Movie{id: $id, title: $title, genre: $genre, year: $year, director: $director}';
  }
}
