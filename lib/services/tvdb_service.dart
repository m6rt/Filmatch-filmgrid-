import 'package:http/http.dart' as http;
import 'dart:convert';

class TMDBService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _apiKey = 'YOUR_TMDB_API_KEY'; // TMDB key alın
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // Popüler filmler
  static Future<List<Map<String, dynamic>>> getPopularMovies() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/movie/popular?api_key=$_apiKey&language=en-US&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> movies = [];

        for (var movie in data['results']) {
          Map<String, dynamic> formattedMovie = await _formatMovie(movie);
          movies.add(formattedMovie);
        }

        return movies;
      }
    } catch (e) {
      print('❌ Error getting popular movies: $e');
    }
    return [];
  }

  // En yüksek puanlı filmler
  static Future<List<Map<String, dynamic>>> getTopRatedMovies() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/movie/top_rated?api_key=$_apiKey&language=en-US&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> movies = [];

        for (var movie in data['results']) {
          Map<String, dynamic> formattedMovie = await _formatMovie(movie);
          movies.add(formattedMovie);
        }

        return movies;
      }
    } catch (e) {
      print('❌ Error getting top rated movies: $e');
    }
    return [];
  }

  // Türe göre arama
  static Future<List<Map<String, dynamic>>> searchMoviesByGenre(
    String genre,
  ) async {
    try {
      // Tür ID'sini al
      int? genreId = await _getGenreId(genre);
      if (genreId == null) return [];

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/discover/movie?api_key=$_apiKey&with_genres=$genreId&language=en-US&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> movies = [];

        for (var movie in data['results']) {
          Map<String, dynamic> formattedMovie = await _formatMovie(movie);
          movies.add(formattedMovie);
        }

        return movies;
      }
    } catch (e) {
      print('❌ Error searching movies by genre: $e');
    }
    return [];
  }

  // Film formatla
  static Future<Map<String, dynamic>> _formatMovie(
    Map<String, dynamic> tmdbMovie,
  ) async {
    // Film detaylarını al
    Map<String, dynamic>? details = await _getMovieDetails(tmdbMovie['id']);

    return {
      'id': tmdbMovie['id'].toString(),
      'title': tmdbMovie['title'] ?? 'Unknown',
      'vote_average': (tmdbMovie['vote_average'] ?? 0.0).toDouble(),
      'overview': tmdbMovie['overview'] ?? 'No overview available',
      'poster_path':
          tmdbMovie['poster_path'] != null
              ? '$_imageBaseUrl${tmdbMovie['poster_path']}'
              : null,
      'year': tmdbMovie['release_date']?.substring(0, 4) ?? 'Unknown',
      'genre': details?['genres'] ?? 'Unknown',
      'director': details?['director'] ?? 'Unknown',
      'cast': details?['cast'] ?? 'Unknown',
      'youtube_key': details?['youtube_key'],
    };
  }

  // Film detayları al
  static Future<Map<String, dynamic>?> _getMovieDetails(int movieId) async {
    try {
      // Credits al
      final creditsResponse = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId/credits?api_key=$_apiKey'),
      );

      // Videos al
      final videosResponse = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId/videos?api_key=$_apiKey'),
      );

      // Movie details al
      final detailsResponse = await http.get(
        Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey'),
      );

      if (creditsResponse.statusCode == 200 &&
          videosResponse.statusCode == 200 &&
          detailsResponse.statusCode == 200) {
        final credits = json.decode(creditsResponse.body);
        final videos = json.decode(videosResponse.body);
        final details = json.decode(detailsResponse.body);

        // Yönetmeni bul
        String director = 'Unknown';
        for (var crew in credits['crew']) {
          if (crew['job'] == 'Director') {
            director = crew['name'];
            break;
          }
        }

        // Oyuncuları al
        List<String> actors = [];
        for (var cast in credits['cast'].take(3)) {
          actors.add(cast['name']);
        }

        // Türleri al
        List<String> genres = [];
        for (var genre in details['genres']) {
          genres.add(genre['name']);
        }

        // YouTube trailer bul
        String? youtubeKey;
        for (var video in videos['results']) {
          if (video['type'] == 'Trailer' && video['site'] == 'YouTube') {
            youtubeKey = video['key'];
            break;
          }
        }

        return {
          'director': director,
          'cast': actors.join(', '),
          'genres': genres.join(', '),
          'youtube_key': youtubeKey,
        };
      }
    } catch (e) {
      print('❌ Error getting movie details: $e');
    }
    return null;
  }

  // Tür ID'sini al
  static Future<int?> _getGenreId(String genreName) async {
    Map<String, int> genreMap = {
      'action': 28,
      'adventure': 12,
      'animation': 16,
      'comedy': 35,
      'crime': 80,
      'documentary': 99,
      'drama': 18,
      'family': 10751,
      'fantasy': 14,
      'history': 36,
      'horror': 27,
      'music': 10402,
      'mystery': 9648,
      'romance': 10749,
      'science fiction': 878,
      'thriller': 53,
      'war': 10752,
      'western': 37,
    };

    return genreMap[genreName.toLowerCase()];
  }
}
