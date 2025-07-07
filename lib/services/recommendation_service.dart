import 'tvdb_service.dart';
import '../models/user_preferences.dart';
import 'dart:math';

class RecommendationService {
  static Future<List<Map<String, dynamic>>> getRecommendedMovies({
    int count = 20,
    List<String> excludeMovies = const [],
  }) async {
    List<Map<String, dynamic>> allMovies = [];

    List<String> likedMovies = UserPreferences.getLikedMovies();
    List<String> dislikedMovies = UserPreferences.getDislikedMovies();

    // Hariç tutulacak filmler listesi
    Set<String> excludeSet = {
      ...excludeMovies,
      ...likedMovies,
      ...dislikedMovies,
    };

    print('🎬 Getting TVDB recommendations...');
    print('👍 Liked movies: ${likedMovies.length}');
    print('👎 Disliked movies: ${dislikedMovies.length}');
    print('🚫 Excluded movies: ${excludeSet.length}');

    if (likedMovies.isEmpty) {
      // 🆕 Yeni kullanıcı - çeşitli popüler filmler
      print('🆕 New user - loading diverse content');
      allMovies = await _getNewUserRecommendations();
    } else {
      // 🧠 Mevcut kullanıcı - kişiselleştirilmiş öneriler
      print('🧠 Existing user - personalized recommendations');
      allMovies = await _getPersonalizedRecommendations();
    }

    // Hariç tutulacak filmleri filtrele
    allMovies =
        allMovies.where((movie) => !excludeSet.contains(movie['id'])).toList();

    // Filmleri filtrele ve sırala
    allMovies = _filterAndRankMovies(allMovies, likedMovies, dislikedMovies);

    // Trailer'ı olan filmleri öncelikle al
    List<Map<String, dynamic>> moviesWithTrailers =
        allMovies.where((movie) => movie['youtube_key'] != null).toList();

    List<Map<String, dynamic>> moviesWithoutTrailers =
        allMovies.where((movie) => movie['youtube_key'] == null).toList();

    // Trailer'ı olanları önce, olmayanları sonra ekle
    List<Map<String, dynamic>> finalMovies = [];
    finalMovies.addAll(moviesWithTrailers);
    finalMovies.addAll(moviesWithoutTrailers);

    // Çeşitlilik için karıştır
    finalMovies.shuffle();

    print('✅ Total recommended movies: ${finalMovies.length}');
    print('🎬 Movies with trailers: ${moviesWithTrailers.length}');

    return finalMovies.take(count).toList();
  }

  // Yeni kullanıcı için öneriler
  static Future<List<Map<String, dynamic>>> _getNewUserRecommendations() async {
    List<Map<String, dynamic>> movies = [];

    try {
      // %40 Popüler filmler
      List<Map<String, dynamic>> popularMovies =
          await TVDBService.getPopularMovies();
      movies.addAll(popularMovies);

      // %30 En yüksek puanlı filmler
      List<Map<String, dynamic>> topRatedMovies =
          await TVDBService.getTopRatedMovies();
      movies.addAll(topRatedMovies);

      // %30 Yeni filmler
      List<Map<String, dynamic>> latestMovies =
          await TVDBService.getLatestMovies();
      movies.addAll(latestMovies);
    } catch (e) {
      print('❌ Error getting new user recommendations: $e');
    }

    return movies;
  }

  // Kişiselleştirilmiş öneriler
  static Future<List<Map<String, dynamic>>>
  _getPersonalizedRecommendations() async {
    List<Map<String, dynamic>> movies = [];

    try {
      // Kullanıcı tercihlerini al
      List<String> preferredGenres = UserPreferences.getPreferredGenres();
      List<String> likedMovies = UserPreferences.getLikedMovies();

      // %50 Beğenilen türlere göre filmler
      for (String genre in preferredGenres.take(3)) {
        List<Map<String, dynamic>> genreMovies =
            await TVDBService.searchMoviesByGenre(genre);
        movies.addAll(genreMovies);
      }

      // %30 Beğenilen filmlere benzer filmler
      for (String movieId in likedMovies.take(2)) {
        List<Map<String, dynamic>> similarMovies =
            await TVDBService.getSimilarMovies(movieId);
        movies.addAll(similarMovies);
      }

      // %20 Çeşitlilik için popüler filmler
      List<Map<String, dynamic>> popularMovies =
          await TVDBService.getPopularMovies();
      movies.addAll(popularMovies.take(10));
    } catch (e) {
      print('❌ Error getting personalized recommendations: $e');
    }

    return movies;
  }

  // Akıllı filtreleme ve sıralama
  static List<Map<String, dynamic>> _filterAndRankMovies(
    List<Map<String, dynamic>> movies,
    List<String> likedMovies,
    List<String> dislikedMovies,
  ) {
    Map<String, Map<String, dynamic>> uniqueMovies = {};
    List<String> preferredGenres = UserPreferences.getPreferredGenres();

    for (var movie in movies) {
      String movieId = movie['id'];

      // Beğenilmeyen ve zaten beğenilen filmleri çıkar
      if (dislikedMovies.contains(movieId) || likedMovies.contains(movieId)) {
        continue;
      }

      // Minimum kalite kontrolü
      if (movie['vote_average'] < 5.0) {
        continue;
      }

      // Temel bilgi kontrolü
      if (movie['title'] == null || movie['title'].isEmpty) {
        continue;
      }

      // Öncelik puanı hesapla
      double priorityScore = _calculatePriorityScore(movie, preferredGenres);
      movie['priority_score'] = priorityScore;

      uniqueMovies[movieId] = movie;
    }

    List<Map<String, dynamic>> result = uniqueMovies.values.toList();

    // Öncelik puanına göre sırala
    result.sort((a, b) {
      double scoreA = a['priority_score'] ?? 0.0;
      double scoreB = b['priority_score'] ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    return result;
  }

  // Gelişmiş öncelik puanı hesaplama
  static double _calculatePriorityScore(
    Map<String, dynamic> movie,
    List<String> preferredGenres,
  ) {
    double score = 0.0;

    // Base score (TVDB rating)
    score += movie['vote_average'] * 0.3;

    // Tür uyumu (0-5 puan)
    String movieGenre = movie['genre'] ?? '';
    int genreMatches = 0;
    for (String genre in preferredGenres) {
      if (movieGenre.toLowerCase().contains(genre.toLowerCase())) {
        genreMatches++;
        score += 1.0;
      }
    }

    // Çoklu tür bonusu
    if (genreMatches > 1) {
      score += 0.5 * genreMatches;
    }

    // Yıl bonusu (yeni filmler)
    int year = int.tryParse(movie['year'] ?? '0') ?? 0;
    if (year >= 2022) {
      score += 1.0;
    } else if (year >= 2018) {
      score += 0.5;
    }

    // Trailer bonusu
    if (movie['youtube_key'] != null) {
      score += 1.0;
    }

    // Popülerlik bonusu
    if (movie['vote_average'] >= 8.0) {
      score += 1.0;
    } else if (movie['vote_average'] >= 7.0) {
      score += 0.5;
    }

    // Rastgele faktör (çeşitlilik için)
    score += Random().nextDouble() * 0.5;

    return score;
  }

  // Türe göre detaylı arama
  static Future<List<Map<String, dynamic>>> searchByGenreDetailed(
    String genre,
  ) async {
    List<Map<String, dynamic>> movies = [];

    try {
      // Türe göre arama
      List<Map<String, dynamic>> genreMovies =
          await TVDBService.searchMoviesByGenre(genre);
      movies.addAll(genreMovies);

      // Türle ilgili kelimeler ile arama
      List<String> relatedTerms = _getRelatedTerms(genre);
      for (String term in relatedTerms.take(2)) {
        List<Map<String, dynamic>> termMovies = await TVDBService.searchMovies(
          term,
        );
        movies.addAll(termMovies);
      }
    } catch (e) {
      print('❌ Error searching by genre: $e');
    }

    return movies;
  }

  // Türle ilgili kelimeler
  static List<String> _getRelatedTerms(String genre) {
    Map<String, List<String>> genreTerms = {
      'action': ['hero', 'fight', 'adventure', 'mission', 'combat', 'warrior'],
      'drama': ['life', 'story', 'family', 'emotion', 'heart', 'relationship'],
      'comedy': ['funny', 'humor', 'laugh', 'comic', 'fun', 'hilarious'],
      'thriller': ['suspense', 'mystery', 'tension', 'danger', 'psychological'],
      'horror': ['scary', 'fear', 'terror', 'nightmare', 'supernatural'],
      'romance': ['love', 'romantic', 'relationship', 'heart', 'passion'],
      'sci-fi': [
        'future',
        'space',
        'technology',
        'alien',
        'robot',
        'cyberpunk',
      ],
      'fantasy': [
        'magic',
        'wizard',
        'dragon',
        'kingdom',
        'mystical',
        'enchanted',
      ],
      'crime': ['detective', 'police', 'criminal', 'investigation', 'justice'],
      'adventure': ['journey', 'quest', 'exploration', 'discovery', 'treasure'],
      'animation': ['cartoon', 'animated', 'family', 'kids', 'disney', 'pixar'],
      'documentary': ['real', 'truth', 'facts', 'history', 'biography'],
      'biography': ['life', 'story', 'real', 'person', 'history', 'memoir'],
      'history': ['historical', 'past', 'war', 'period', 'ancient', 'medieval'],
      'war': ['battle', 'military', 'soldier', 'conflict', 'combat', 'victory'],
      'western': [
        'cowboy',
        'frontier',
        'sheriff',
        'gunfight',
        'outlaw',
        'ranch',
      ],
      'musical': ['song', 'music', 'dance', 'musical', 'broadway', 'melody'],
      'sport': [
        'sports',
        'game',
        'team',
        'competition',
        'championship',
        'athlete',
      ],
    };

    return genreTerms[genre.toLowerCase()] ?? [genre];
  }
}
