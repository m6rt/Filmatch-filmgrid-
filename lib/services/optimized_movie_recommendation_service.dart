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

  Map<String, dynamic> toJson() => {
    'type': type,
    'value': value,
    'weight': weight,
  };

  factory UserPreference.fromJson(Map<String, dynamic> json) => UserPreference(
    type: json['type'],
    value: json['value'],
    weight: json['weight'].toDouble(),
  );
}

class OptimizedMovieRecommendationService {
  static final OptimizedMovieRecommendationService _instance =
      OptimizedMovieRecommendationService._internal();
  factory OptimizedMovieRecommendationService() => _instance;
  OptimizedMovieRecommendationService._internal();

  // Optimized data structures
  List<Movie> _currentBatch = [];
  List<UserPreference> _userPreferences = [];
  Map<int, SwipeAction> _userActions = {};

  // Pagination
  int _currentPage = 0;
  final int _batchSize = 50; // Her seferde 50 film yükle
  int _totalMovies = 0;

  // Kullanıcı istatistikleri
  int _likedCount = 0;
  int _dislikedCount = 0;

  // Caching ve indexing
  Map<String, List<int>> _genreIndex = {};
  Map<String, List<int>> _directorIndex = {};
  Map<String, List<int>> _yearRangeIndex = {};

  // Getter'lar
  List<Movie> get currentBatch => _currentBatch;
  int get likedCount => _likedCount;
  int get dislikedCount => _dislikedCount;
  int get totalMovies => _totalMovies;

  // İlk yükleme - sadece metadata ve indexler
  Future<void> initializeService() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/movies_database.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _totalMovies = jsonList.length;

      // Index'leri oluştur (sadece ID'ler)
      _buildIndexes(jsonList);

      // İlk batch'i yükle
      await _loadNextBatch();

      print('✅ Servis başlatıldı. Toplam film: $_totalMovies');
    } catch (e) {
      print('❌ Servis başlatma hatası: $e');
    }
  }

  // Index'leri oluştur - performans için
  void _buildIndexes(List<dynamic> jsonList) {
    _genreIndex.clear();
    _directorIndex.clear();
    _yearRangeIndex.clear();

    for (int i = 0; i < jsonList.length; i++) {
      final movieData = jsonList[i];

      // Tür indexi
      if (movieData['genre'] != null) {
        for (String genre in List<String>.from(movieData['genre'])) {
          _genreIndex.putIfAbsent(genre.toLowerCase(), () => []).add(i);
        }
      }

      // Yönetmen indexi
      if (movieData['director'] != null) {
        String director = movieData['director'].toString().toLowerCase();
        _directorIndex.putIfAbsent(director, () => []).add(i);
      }

      // Yıl aralığı indexi
      if (movieData['year'] != null) {
        int year = movieData['year'];
        String yearRange = _getYearRange(year);
        _yearRangeIndex.putIfAbsent(yearRange, () => []).add(i);
      }
    }

    print('🗂️ Indexler olusturuldu:');
    print('  - Tur: ${_genreIndex.length}');
    print('  - Yonetmen: ${_directorIndex.length}');
    print('  - Yil araligi: ${_yearRangeIndex.length}');
  }

  // Akıllı batch yükleme
  Future<void> _loadNextBatch() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/movies_database.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      List<Movie> candidateMovies = [];

      if (_userPreferences.isEmpty) {
        // İlk yükleme - rastgele filmler
        final shuffledIndices = List.generate(jsonList.length, (i) => i)
          ..shuffle();
        final startIndex = _currentPage * _batchSize;
        final endIndex = min(startIndex + _batchSize, jsonList.length);

        for (int i = startIndex; i < endIndex; i++) {
          final movieIndex = shuffledIndices[i];
          candidateMovies.add(Movie.fromJson(jsonList[movieIndex]));
        }
      } else {
        // Tercihlere göre akıllı yükleme
        candidateMovies = await _loadSmartBatch(jsonList);
      }

      // Zaten swipe edilmiş filmleri filtrele
      candidateMovies =
          candidateMovies
              .where((movie) => !_userActions.containsKey(movie.id))
              .toList();

      _currentBatch = candidateMovies;
      _currentPage++;

      print('📦 Yeni batch yüklendi: ${candidateMovies.length} film');
    } catch (e) {
      print('❌ Batch yükleme hatası: $e');
    }
  }

  // Tercihlere göre akıllı film seçimi
  Future<List<Movie>> _loadSmartBatch(List<dynamic> jsonList) async {
    Set<int> recommendedIndices = {};

    // En güçlü tercihlere göre filmler bul
    final sortedPrefs = List<UserPreference>.from(_userPreferences)
      ..sort((a, b) => b.weight.abs().compareTo(a.weight.abs()));

    for (var pref in sortedPrefs.take(10)) {
      // En güçlü 10 tercihi kullan
      if (pref.weight <= 0) continue; // Sadece pozitif tercihleri kullan

      List<int>? indices;
      switch (pref.type) {
        case 'genre':
          indices = _genreIndex[pref.value.toLowerCase()];
          break;
        case 'director':
          indices = _directorIndex[pref.value.toLowerCase()];
          break;
        case 'year_range':
          indices = _yearRangeIndex[pref.value];
          break;
      }

      if (indices != null) {
        recommendedIndices.addAll(
          indices.take(20),
        ); // Her tercihten max 20 film
      }

      if (recommendedIndices.length >= _batchSize * 2)
        break; // Yeterli aday var
    }

    // Rastgele filmler ekle (çeşitlilik için)
    final randomIndices = List.generate(jsonList.length, (i) => i)..shuffle();
    recommendedIndices.addAll(randomIndices.take(_batchSize ~/ 2));

    // Movie nesnelerine dönüştür
    final movies =
        recommendedIndices
            .take(_batchSize * 2) // Fazladan yükle, sonra skorla
            .map((index) => Movie.fromJson(jsonList[index]))
            .toList();

    // Skorla ve en iyileri seç
    movies.sort(
      (a, b) => _calculateMovieScore(b).compareTo(_calculateMovieScore(a)),
    );

    return movies.take(_batchSize).toList();
  }

  // Optimize edilmiş skor hesaplama
  double _calculateMovieScore(Movie movie) {
    if (_userActions.containsKey(movie.id)) return -1000.0;

    double score = 0.0;

    // Tür skoru (optimize edilmiş)
    for (String genre in movie.genre) {
      final pref = _findPreference('genre', genre.toLowerCase());
      if (pref != null) {
        score += pref.weight * 3.0;
      }
    }

    // Yönetmen skoru
    final directorPref = _findPreference(
      'director',
      movie.director.toLowerCase(),
    );
    if (directorPref != null) {
      score += directorPref.weight * 4.0;
    }

    // Yıl aralığı skoru
    final yearRange = _getYearRange(movie.year);
    final yearPref = _findPreference('year_range', yearRange);
    if (yearPref != null) {
      score += yearPref.weight * 2.0;
    }

    // Rastgele faktör
    score += Random().nextDouble() * 0.5;

    return score;
  }

  // Optimize edilmiş tercih bulma
  UserPreference? _findPreference(String type, String value) {
    for (var pref in _userPreferences) {
      if (pref.type == type && pref.value == value) {
        return pref;
      }
    }
    return null;
  }

  // Kullanıcı eylemini kaydet
  void recordUserAction(Movie movie, SwipeAction action) {
    _userActions[movie.id] = action;

    if (action == SwipeAction.like) {
      _likedCount++;
      _addPositivePreferences(movie);
    } else {
      _dislikedCount++;
      _addNegativePreferences(movie);
    }

    // Batch bitmek üzereyse yeni batch yükle
    _checkAndLoadNextBatch();
  }

  // Batch kontrolü ve otomatik yükleme
  void _checkAndLoadNextBatch() {
    final remainingMovies =
        _currentBatch
            .where((movie) => !_userActions.containsKey(movie.id))
            .length;

    if (remainingMovies <= 5) {
      // 5 film kaldığında yeni batch yükle
      _loadNextBatch();
    }
  }

  // Sonraki filmi al
  Movie? getNextMovie() {
    // Mevcut batch'ten swipe edilmemiş film bul
    for (Movie movie in _currentBatch) {
      if (!_userActions.containsKey(movie.id)) {
        return movie;
      }
    }

    // Batch boşsa yeni batch yükle
    if (_currentBatch.isEmpty || _currentPage * _batchSize < _totalMovies) {
      _loadNextBatch();
      return getNextMovie(); // Recursive call
    }

    return null;
  }

  // Mevcut metodlar (optimizasyonlarla)
  void _addPositivePreferences(Movie movie) {
    for (String genre in movie.genre) {
      _updatePreference('genre', genre.toLowerCase(), 0.3);
    }
    _updatePreference('director', movie.director.toLowerCase(), 0.4);
    _updatePreference('year_range', _getYearRange(movie.year), 0.2);
  }

  void _addNegativePreferences(Movie movie) {
    for (String genre in movie.genre) {
      _updatePreference('genre', genre.toLowerCase(), -0.2);
    }
    _updatePreference('director', movie.director.toLowerCase(), -0.3);
    _updatePreference('year_range', _getYearRange(movie.year), -0.1);
  }

  void _updatePreference(String type, String value, double weightChange) {
    final existingPref = _findPreference(type, value);

    if (existingPref != null) {
      final index = _userPreferences.indexOf(existingPref);
      final newWeight = (existingPref.weight + weightChange).clamp(-2.0, 2.0);
      _userPreferences[index] = UserPreference(
        type: type,
        value: value,
        weight: newWeight,
      );
    } else {
      _userPreferences.add(
        UserPreference(type: type, value: value, weight: weightChange),
      );
    }
  }

  String _getYearRange(int year) {
    int rangeStart = (year ~/ 10) * 10;
    return '${rangeStart}s';
  }

  void printUserPreferences() {
    print('\n📊 Kullanıcı Tercihleri:');
    print('👍 Beğenilen: $_likedCount film');
    print('👎 Beğenilmeyen: $_dislikedCount film');
    print('📦 Mevcut batch: ${_currentBatch.length} film');
    print('📄 Sayfa: $_currentPage');

    if (_userPreferences.isNotEmpty) {
      print('\n🎯 En Güçlü Tercihler:');
      final sortedPrefs = List<UserPreference>.from(_userPreferences)
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

  // Tercihleri kaydet/yükle (persistent storage için)
  Map<String, dynamic> exportPreferences() {
    return {
      'preferences': _userPreferences.map((p) => p.toJson()).toList(),
      'liked_count': _likedCount,
      'disliked_count': _dislikedCount,
      'user_actions': _userActions.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
    };
  }

  void importPreferences(Map<String, dynamic> data) {
    if (data['preferences'] != null) {
      _userPreferences =
          (data['preferences'] as List)
              .map((p) => UserPreference.fromJson(p))
              .toList();
    }
    _likedCount = data['liked_count'] ?? 0;
    _dislikedCount = data['disliked_count'] ?? 0;

    if (data['user_actions'] != null) {
      _userActions = (data['user_actions'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          int.parse(k),
          v == 'SwipeAction.like' ? SwipeAction.like : SwipeAction.dislike,
        ),
      );
    }
  }

  void reset() {
    _userPreferences.clear();
    _userActions.clear();
    _likedCount = 0;
    _dislikedCount = 0;
    _currentPage = 0;
    _currentBatch.clear();
  }
}
