class Movie {
  final int id;
  final String title;
  final String posterUrl;
  final int year;
  final List<String> genre;
  final String director;
  final List<String> cast;
  final String description;
  final String? trailerUrl;

  Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.year,
    required this.genre,
    required this.director,
    required this.cast,
    required this.description,
    this.trailerUrl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      posterUrl: json['poster_url'] ?? '',
      year: json['year'] ?? 0,
      genre: List<String>.from(json['genre'] ?? []),
      director: json['director'] ?? '',
      cast: List<String>.from(json['cast'] ?? []),
      description: json['description'] ?? '',
      trailerUrl: json['trailer_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_url': posterUrl,
      'year': year,
      'genre': genre,
      'director': director,
      'cast': cast,
      'description': description,
      'trailer_url': trailerUrl,
    };
  }

  @override
  String toString() {
    return 'Movie{id: $id, title: $title, genre: $genre, year: $year, director: $director}';
  }
}
