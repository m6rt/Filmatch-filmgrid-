import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/movie.dart';

enum SwipeAction { like, dislike }

class UserPreference {
  final String type;
  final String value;
  final double weight;

  UserPreference({
    required this.type,
    required this.value,
    required this.weight,
  });
}

class MovieRecommendationService {
  static final MovieRecommendationService _instance =
      MovieRecommendationService._internal();
  factory MovieRecommendationService() => _instance;
  MovieRecommendationService._internal();

  List<Movie> _allMovies = [];
  List<Movie> _recommendedMovies = [];
  List<UserPreference> _userPreferences = [];
  Map<int, SwipeAction> _userActions = {};

  // Kullanıcının beğendiği/beğenmediği film sayıları
  int _likedCount = 0;
  int _dislikedCount = 0;

  // Getter'lar
  List<Movie> get allMovies => _allMovies;
  List<Movie> get recommendedMovies => _recommendedMovies;
  int get likedCount => _likedCount;
  int get dislikedCount => _dislikedCount;

  // Film veritabanını yükle
  Future<void> loadMovies() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/movies_database.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _allMovies = jsonList.map((json) => Movie.fromJson(json)).toList();

      // İlk öneriler için rastgele filmler seç
      _recommendedMovies = List.from(_allMovies)..shuffle();

      print('✅ ${_allMovies.length} film yüklendi');
    } catch (e) {
      print('❌ Film yükleme hatası: $e');
    }
  }

  // Kullanıcı eylemi kaydet ve tercihleri güncelle
  void recordUserAction(Movie movie, SwipeAction action) {
    _userActions[movie.id] = action;

    if (action == SwipeAction.like) {
      _likedCount++;
      _addPositivePreferences(movie);
    } else {
      _dislikedCount++;
      _addNegativePreferences(movie);
    }

    _updateRecommendations();
  }

  // Pozitif tercihler ekle (beğenilen film özellikleri)
  void _addPositivePreferences(Movie movie) {
    // Türler için tercih ekle
    for (String genre in movie.genre) {
      _updatePreference('genre', genre, 0.3);
    }

    // Yönetmen için tercih ekle
    _updatePreference('director', movie.director, 0.4);

    // Yıl aralığı için tercih ekle (±5 yıl)
    String yearRange = _getYearRange(movie.year);
    _updatePreference('year_range', yearRange, 0.2);

    // Oyuncular için tercih ekle
    for (String actor in movie.cast) {
      _updatePreference('actor', actor, 0.1);
    }
  }

  // Negatif tercihler ekle (beğenilmeyen film özellikleri)
  void _addNegativePreferences(Movie movie) {
    // Türler için negatif tercih ekle
    for (String genre in movie.genre) {
      _updatePreference('genre', genre, -0.2);
    }

    // Yönetmen için negatif tercih ekle
    _updatePreference('director', movie.director, -0.3);

    // Yıl aralığı için negatif tercih ekle
    String yearRange = _getYearRange(movie.year);
    _updatePreference('year_range', yearRange, -0.1);
  }

  // Tercihi güncelle veya ekle
  void _updatePreference(String type, String value, double weightChange) {
    int existingIndex = _userPreferences.indexWhere(
      (pref) => pref.type == type && pref.value == value,
    );

    if (existingIndex != -1) {
      // Mevcut tercihi güncelle
      UserPreference existing = _userPreferences[existingIndex];
      double newWeight = (existing.weight + weightChange).clamp(-2.0, 2.0);

      _userPreferences[existingIndex] = UserPreference(
        type: type,
        value: value,
        weight: newWeight,
      );
    } else {
      // Yeni tercih ekle
      _userPreferences.add(
        UserPreference(type: type, value: value, weight: weightChange),
      );
    }
  }

  // Yıl aralığını hesapla
  String _getYearRange(int year) {
    int rangeStart = (year ~/ 10) * 10;
    return '${rangeStart}s';
  }

  // Film skorunu hesapla
  double _calculateMovieScore(Movie movie) {
    double score = 0.0;

    // Eğer film daha önce swipe edilmişse, skoru sıfır yap
    if (_userActions.containsKey(movie.id)) {
      return -1000.0;
    }

    // Tür skoru
    for (String genre in movie.genre) {
      UserPreference? genrePref =
          _userPreferences
                  .where((pref) => pref.type == 'genre' && pref.value == genre)
                  .isNotEmpty
              ? _userPreferences.firstWhere(
                (pref) => pref.type == 'genre' && pref.value == genre,
              )
              : null;

      if (genrePref != null) {
        score += genrePref.weight * 3.0; // Tür ağırlığı yüksek
      }
    }

    // Yönetmen skoru
    UserPreference? directorPref =
        _userPreferences
                .where(
                  (pref) =>
                      pref.type == 'director' && pref.value == movie.director,
                )
                .isNotEmpty
            ? _userPreferences.firstWhere(
              (pref) => pref.type == 'director' && pref.value == movie.director,
            )
            : null;

    if (directorPref != null) {
      score += directorPref.weight * 4.0; // Yönetmen ağırlığı en yüksek
    }

    // Yıl aralığı skoru
    String yearRange = _getYearRange(movie.year);
    UserPreference? yearPref =
        _userPreferences
                .where(
                  (pref) =>
                      pref.type == 'year_range' && pref.value == yearRange,
                )
                .isNotEmpty
            ? _userPreferences.firstWhere(
              (pref) => pref.type == 'year_range' && pref.value == yearRange,
            )
            : null;

    if (yearPref != null) {
      score += yearPref.weight * 2.0;
    }

    // Oyuncu skoru
    for (String actor in movie.cast) {
      UserPreference? actorPref =
          _userPreferences
                  .where((pref) => pref.type == 'actor' && pref.value == actor)
                  .isNotEmpty
              ? _userPreferences.firstWhere(
                (pref) => pref.type == 'actor' && pref.value == actor,
              )
              : null;

      if (actorPref != null) {
        score += actorPref.weight * 1.0;
      }
    }

    // Rastgele faktör ekle (çeşitlilik için)
    score += Random().nextDouble() * 0.5;

    return score;
  }

  // Önerileri güncelle
  void _updateRecommendations() {
    if (_userPreferences.isEmpty) {
      // Henüz tercih yoksa, rastgele sırala
      _recommendedMovies = List.from(_allMovies)..shuffle();
      return;
    }

    // Tüm filmleri skorla ve sırala
    List<MapEntry<Movie, double>> scoredMovies =
        _allMovies
            .map((movie) => MapEntry(movie, _calculateMovieScore(movie)))
            .toList();

    // Skora göre sırala (yüksekten düşüğe)
    scoredMovies.sort((a, b) => b.value.compareTo(a.value));

    // Sıralanmış filmleri al
    _recommendedMovies = scoredMovies.map((entry) => entry.key).toList();

    print(
      '🎬 Öneriler güncellendi. En yüksek skor: ${scoredMovies.first.value.toStringAsFixed(2)}',
    );
  }

  // Sonraki filmi al
  Movie? getNextMovie() {
    // Swipe edilmemiş filmi bul
    for (Movie movie in _recommendedMovies) {
      if (!_userActions.containsKey(movie.id)) {
        return movie;
      }
    }

    // Eğer tüm filmler swipe edilmişse, listeyi yeniden karıştır
    if (_userActions.length >= _allMovies.length) {
      print('🔄 Tüm filmler görüldü, liste yenileniyor...');
      _userActions.clear();
      _updateRecommendations();
      return _recommendedMovies.isNotEmpty ? _recommendedMovies.first : null;
    }

    return null;
  }

  // Kullanıcı tercihlerini yazdır (debug için)
  void printUserPreferences() {
    print('\n📊 Kullanıcı Tercihleri:');
    print('👍 Beğenilen: $_likedCount film');
    print('👎 Beğenilmeyen: $_dislikedCount film');

    if (_userPreferences.isNotEmpty) {
      print('\n🎯 En Güçlü Tercihler:');
      List<UserPreference> sortedPrefs = List.from(_userPreferences)
        ..sort((a, b) => b.weight.abs().compareTo(a.weight.abs()));

      for (int i = 0; i < min(10, sortedPrefs.length); i++) {
        UserPreference pref = sortedPrefs[i];
        String emoji = pref.weight > 0 ? '✅' : '❌';
        print(
          '$emoji ${pref.type}: ${pref.value} (${pref.weight.toStringAsFixed(2)})',
        );
      }
    }
    print('');
  }

  // Service'i sıfırla
  void reset() {
    _userPreferences.clear();
    _userActions.clear();
    _likedCount = 0;
    _dislikedCount = 0;
    _updateRecommendations();
  }
}
