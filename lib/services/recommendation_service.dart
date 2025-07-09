import 'dart:convert';
import 'package:filmgrid/services/user_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:filmgrid/services/tvdb_service.dart';
import 'package:filmgrid/services/youtube_service.dart';

class RecommendationService {
  static List<Map<String, dynamic>> _moviePool = [];
  static List<String> _shownMovies = [];
  
  // Kullanıcının tercihlerini analiz et ve kişiselleştirilmiş öneriler getir
  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    int count = 20,
    List<String> excludeMovies = const [],
  }) async {
    try {
      print('🤖 Analyzing user preferences...');
      
      // Kullanıcının tercihlerini al
      Map<String, dynamic> userProfile = await _analyzeUserProfile();
      
      // Tercihlere göre filmler getir
      List<Map<String, dynamic>> recommendations = await _getRecommendationsBasedOnProfile(
        userProfile,
        count,
        excludeMovies,
      );
      
      // Öncelik puanlarına göre sırala
      recommendations.sort((a, b) => 
        (b['priority_score'] as double).compareTo(a['priority_score'] as double)
      );
      
      print('🎬 Generated ${recommendations.length} personalized recommendations');
      return recommendations;
      
    } catch (e) {
      print('❌ Error in personalized recommendations: $e');
      return await _getFallbackRecommendations(count);
    }
  }

  // Kullanıcının profil analizini yap - DÜZELTİLMİŞ VERSİYON
  static Future<Map<String, dynamic>> _analyzeUserProfile() async {
    try {
      // UserPreferences'den verileri al
      List<String> likedGenres = await UserPreferences.getLikedGenres();
      List<String> likedDirectors = await UserPreferences.getLikedDirectors();
      List<String> likedActors = await UserPreferences.getLikedActors();
      
      List<String> dislikedGenres = await UserPreferences.getDislikedGenres();
      List<String> dislikedDirectors = await UserPreferences.getDislikedDirectors();
      List<String> dislikedActors = await UserPreferences.getDislikedActors();
      
      // Sevilen türleri analiz et
      Map<String, int> genreScores = {};
      Map<String, int> directorScores = {};
      Map<String, int> actorScores = {};
      
      // Sevilen filmlerin analizi
      for (var genre in likedGenres) {
        genreScores[genre] = (genreScores[genre] ?? 0) + 3;
      }
      
      for (var director in likedDirectors) {
        directorScores[director] = (directorScores[director] ?? 0) + 2;
      }
      
      for (var actor in likedActors) {
        actorScores[actor] = (actorScores[actor] ?? 0) + 1;
      }
      
      // Sevilmeyen filmlerin analizi (negatif puan)
      for (var genre in dislikedGenres) {
        genreScores[genre] = (genreScores[genre] ?? 0) - 2;
      }
      
      for (var director in dislikedDirectors) {
        directorScores[director] = (directorScores[director] ?? 0) - 1;
      }
      
      for (var actor in dislikedActors) {
        actorScores[actor] = (actorScores[actor] ?? 0) - 1;
      }
      
      // En sevilen türleri bul
      List<String> preferredGenres = genreScores.entries
          .where((entry) => entry.value > 0)
          .map((entry) => entry.key)
          .toList();
      
      List<String> preferredDirectors = directorScores.entries
          .where((entry) => entry.value > 0)
          .map((entry) => entry.key)
          .toList();
      
      List<String> preferredActors = actorScores.entries
          .where((entry) => entry.value > 0)
          .map((entry) => entry.key)
          .toList();
      
      print('🎯 User prefers: ${preferredGenres.join(', ')}');
      print('🎬 Liked directors: ${preferredDirectors.join(', ')}');
      print('⭐ Liked actors: ${preferredActors.join(', ')}');
      
      return {
        'preferred_genres': preferredGenres,
        'preferred_directors': preferredDirectors,
        'preferred_actors': preferredActors,
        'avoided_genres': genreScores.entries
            .where((entry) => entry.value < 0)
            .map((entry) => entry.key)
            .toList(),
        'genre_scores': genreScores,
        'director_scores': directorScores,
        'actor_scores': actorScores,
      };
    } catch (e) {
      print('❌ Error analyzing user profile: $e');
      // Hata durumunda boş profil döndür
      return {
        'preferred_genres': <String>[],
        'preferred_directors': <String>[],
        'preferred_actors': <String>[],
        'avoided_genres': <String>[],
        'genre_scores': <String, int>{},
        'director_scores': <String, int>{},
        'actor_scores': <String, int>{},
      };
    }
  }

  // Profile göre film önerilerini getir
  static Future<List<Map<String, dynamic>>> _getRecommendationsBasedOnProfile(
    Map<String, dynamic> userProfile,
    int count,
    List<String> excludeMovies,
  ) async {
    List<Map<String, dynamic>> recommendations = [];
    
    try {
      // Sevilen türlere göre filmler getir
      List<String> preferredGenres = List<String>.from(userProfile['preferred_genres'] ?? []);
      
      if (preferredGenres.isNotEmpty) {
        for (String genre in preferredGenres.take(3)) {
          print('🔍 Searching for $genre movies...');
          
          // TVDB'den o türe ait filmler getir
          List<Map<String, dynamic>> genreMovies = await TVDBService.searchMoviesByGenre(genre);
          
          // YouTube trailer'ı olan filmleri filtrele
          for (var movie in genreMovies) {
            if (movie['youtube_key'] != null && 
                !excludeMovies.contains(movie['id']) &&
                !_shownMovies.contains(movie['id'])) {
              
              // Kullanıcının profiline göre priority score hesapla
              double personalizedScore = _calculatePersonalizedScore(movie, userProfile);
              movie['priority_score'] = personalizedScore;
              
              recommendations.add(movie);
            }
          }
        }
      }
      
      // Sevilen yönetmenlere göre filmler getir
      List<String> preferredDirectors = List<String>.from(userProfile['preferred_directors'] ?? []);
      for (String director in preferredDirectors.take(2)) {
        print('🎬 Searching for $director movies...');
        
        List<Map<String, dynamic>> directorMovies = await TVDBService.searchMovies(director);
        
        for (var movie in directorMovies) {
          if (movie['youtube_key'] != null && 
              !excludeMovies.contains(movie['id']) &&
              !_shownMovies.contains(movie['id'])) {
            
            double personalizedScore = _calculatePersonalizedScore(movie, userProfile);
            movie['priority_score'] = personalizedScore;
            
            recommendations.add(movie);
          }
        }
      }
      
      // Eğer yeterli öneri yoksa, popüler filmlerden ekle
      if (recommendations.length < count) {
        print('🔄 Adding popular movies to fill recommendations...');
        
        List<Map<String, dynamic>> popularMovies = await TVDBService.getPopularMovies();
        
        for (var movie in popularMovies) {
          if (movie['youtube_key'] != null && 
              !excludeMovies.contains(movie['id']) &&
              !_shownMovies.contains(movie['id']) &&
              !recommendations.any((r) => r['id'] == movie['id'])) {
            
            double personalizedScore = _calculatePersonalizedScore(movie, userProfile);
            movie['priority_score'] = personalizedScore;
            
            recommendations.add(movie);
          }
          
          if (recommendations.length >= count) break;
        }
      }
      
    } catch (e) {
      print('❌ Error getting recommendations: $e');
    }
    
    // Duplicates'i kaldır
    recommendations = _removeDuplicates(recommendations);
    
    return recommendations.take(count).toList();
  }

  // Kişiselleştirilmiş puan hesapla
  static double _calculatePersonalizedScore(
    Map<String, dynamic> movie, 
    Map<String, dynamic> userProfile
  ) {
    double score = (movie['vote_average'] as num?)?.toDouble() ?? 5.0;
    
    try {
      // Tür bonusu
      String movieGenre = movie['genre']?.toString() ?? '';
      Map<String, int> genreScores = Map<String, int>.from(userProfile['genre_scores'] ?? {});
      
      for (String genre in movieGenre.split(', ')) {
        if (genreScores.containsKey(genre)) {
          score += (genreScores[genre]! * 0.5);
        }
      }
      
      // Yönetmen bonusu
      String director = movie['director']?.toString() ?? '';
      Map<String, int> directorScores = Map<String, int>.from(userProfile['director_scores'] ?? {});
      
      if (directorScores.containsKey(director)) {
        score += (directorScores[director]! * 0.8);
      }
      
      // Oyuncu bonusu
      String cast = movie['cast']?.toString() ?? '';
      Map<String, int> actorScores = Map<String, int>.from(userProfile['actor_scores'] ?? {});
      
      for (String actor in cast.split(', ')) {
        if (actorScores.containsKey(actor)) {
          score += (actorScores[actor]! * 0.3);
        }
      }
      
      // Yeni film bonusu
      String year = movie['year']?.toString() ?? '';
      if (year != 'Unknown') {
        int? movieYear = int.tryParse(year);
        if (movieYear != null && movieYear >= 2020) {
          score += 0.5;
        }
      }
    } catch (e) {
      print('❌ Error calculating personalized score: $e');
    }
    
    return score.clamp(0.0, 10.0);
  }

  // Duplicates'i kaldır
  static List<Map<String, dynamic>> _removeDuplicates(List<Map<String, dynamic>> movies) {
    Map<String, Map<String, dynamic>> uniqueMovies = {};
    
    for (var movie in movies) {
      String id = movie['id'].toString();
      if (!uniqueMovies.containsKey(id)) {
        uniqueMovies[id] = movie;
      }
    }
    
    return uniqueMovies.values.toList();
  }

  // Gösterilen filmleri kaydet
  static void markAsShown(String movieId) {
    if (!_shownMovies.contains(movieId)) {
      _shownMovies.add(movieId);
    }
  }

  // Tür bazlı detaylı arama
  static Future<List<Map<String, dynamic>>> searchByGenreDetailed(String genre) async {
    try {
      print('🔍 Searching detailed movies for genre: $genre');
      
      // TVDB'den o türe ait filmler getir
      List<Map<String, dynamic>> movies = await TVDBService.searchMoviesByGenre(genre);
      
      // YouTube trailer'larını ekle
      for (var movie in movies) {
        if (movie['youtube_key'] == null) {
          String? youtubeKey = await YouTubeService.getMovieTrailer(
            movie['title'] ?? '',
            movie['year'] ?? '',
          );
          movie['youtube_key'] = youtubeKey;
        }
      }
      
      // Trailer'ı olan filmleri filtrele
      List<Map<String, dynamic>> moviesWithTrailers = movies
          .where((movie) => movie['youtube_key'] != null)
          .toList();
      
      print('🎬 Found ${moviesWithTrailers.length} movies for genre: $genre');
      return moviesWithTrailers;
      
    } catch (e) {
      print('❌ Error searching by genre: $e');
      return [];
    }
  }

  // Fallback öneriler (aynı kalıyor...)
  static Future<List<Map<String, dynamic>>> _getFallbackRecommendations(int count) async {
    // Önceki fallback movies listesi aynen kalıyor
    List<Map<String, dynamic>> fallbackMovies = [
      // ... önceki fallback movies ...
    ];
    
    fallbackMovies.shuffle();
    return fallbackMovies
        .where((movie) => !_shownMovies.contains(movie['id']))
        .take(count)
        .toList();
  }

  // Benzer filmler öner
  static Future<List<Map<String, dynamic>>> getSimilarMovies(
    Map<String, dynamic> currentMovie,
    int count,
  ) async {
    try {
      String movieId = currentMovie['id'].toString();
      
      // TVDB'den benzer filmler getir
      List<Map<String, dynamic>> similarMovies = await TVDBService.getSimilarMovies(movieId);
      
      // YouTube trailer'larını ekle
      for (var movie in similarMovies) {
        if (movie['youtube_key'] == null) {
          String? youtubeKey = await YouTubeService.getMovieTrailer(
            movie['title'] ?? '',
            movie['year'] ?? '',
          );
          movie['youtube_key'] = youtubeKey;
        }
      }
      
      // Trailer'ı olan filmleri filtrele
      List<Map<String, dynamic>> moviesWithTrailers = similarMovies
          .where((movie) => movie['youtube_key'] != null)
          .where((movie) => !_shownMovies.contains(movie['id']))
          .take(count)
          .toList();
      
      return moviesWithTrailers;
      
    } catch (e) {
      print('❌ Error getting similar movies: $e');
      return [];
    }
  }

  // Öneri cache'ini temizle
  static void clearCache() {
    _moviePool.clear();
    _shownMovies.clear();
  }

  // Eski method - geriye dönük uyumluluk için
  static Future<List<Map<String, dynamic>>> getRecommendedMovies({
    int count = 20,
    List<String> excludeMovies = const [],
  }) async {
    return await getPersonalizedRecommendations(
      count: count,
      excludeMovies: excludeMovies,
    );
  }
}