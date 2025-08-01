class Movie {
  final int id;
  final String title;
  final String overview; // description yerine overview
  final String? trailerUrl; // trailer URL'si
  final String posterPath; // poster_path
  final String? backdropPath; // backdrop_path
  final String releaseDate; // release_date
  final List<String> genre; // genre string listesi (ID'lerden dönüştürülecek)
  final List<int> genreIds; // Orijinal genre ID'leri
  final double voteAverage; // vote_average
  final int voteCount; // vote_count
  final double popularity;
  final bool adult;
  final String originalLanguage; // original_language
  final String originalTitle; // original_title

  // Cast ve director kaldırıldı

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.trailerUrl,
    required this.posterPath,
    this.backdropPath,
    required this.releaseDate,
    required this.genre,
    required this.genreIds,
    required this.voteAverage,
    required this.voteCount,
    required this.popularity,
    required this.adult,
    required this.originalLanguage,
    required this.originalTitle,
  });

  // Genre ID'den isim eşleştirmesi
  static const Map<int, String> genreMap = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Science Fiction',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  // Year getter (releaseDate'den yıl çıkarır)
  int get year {
    try {
      return int.parse(releaseDate.split('-')[0]);
    } catch (e) {
      return DateTime.now().year;
    }
  }

  // Description getter (backward compatibility için)
  String get description => overview;

  // PosterUrl getter (backward compatibility için)
  String get posterUrl =>
      posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  // Director ve cast getter'ları (boş string döndürür, backward compatibility için)
  String get director => '';
  List<String> get cast => [];

  factory Movie.fromJson(Map<String, dynamic> json) {
    final genreIds = List<int>.from(json['genre_ids'] ?? []);
    final genres =
        genreIds
            .map((id) => genreMap[id] ?? 'Unknown')
            .where((genre) => genre != 'Unknown')
            .toList();

    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      overview: json['overview'] ?? 'No description available',
      trailerUrl: json['trailer'], // JSON'dan trailer URL'si
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'],
      releaseDate:
          json['release_date'] ??
          DateTime.now().toIso8601String().split('T')[0],
      genre: genres,
      genreIds: genreIds,
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      popularity: (json['popularity'] ?? 0.0).toDouble(),
      adult: json['adult'] ?? false,
      originalLanguage: json['original_language'] ?? 'en',
      originalTitle: json['original_title'] ?? 'Unknown Title',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'trailer': trailerUrl,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'release_date': releaseDate,
      'genre_ids': genreIds,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'popularity': popularity,
      'adult': adult,
      'original_language': originalLanguage,
      'original_title': originalTitle,
    };
  }

  @override
  String toString() {
    return 'Movie{id: $id, title: $title, genre: $genre, year: $year}';
  }
}
