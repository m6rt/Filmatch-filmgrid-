import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/movie.dart';

enum SwipeAction { like, dislike }

class UserAction {
  final Movie movie;
  final SwipeAction action;
  final DateTime timestamp;

  UserAction({
    required this.movie,
    required this.action,
    required this.timestamp,
  });
}

class UserPreference {
  final String type; // 'genre', 'director', 'year_range'
  final String value;
  double weight;
  int actionCount;

  UserPreference({
    required this.type,
    required this.value,
    this.weight = 0.0,
    this.actionCount = 0,
  });
}

class BatchOptimizedMovieService {
  // Film veritabanı
  List<Movie> _allMovies = [];

  // Batch sistem
  List<Movie> _currentBatch = [];
  List<Movie> _nextBatch = [];
  int _currentIndex = 0;
  final int _batchSize = 10;

  // Tercih tracking
  List<UserAction> _pendingActions = [];
  List<UserPreference> _userPreferences = [];

  // Durum kontrolleri
  bool _isInitialized = false;
  bool _isPreparingNextBatch = false;

  // Cache
  Map<int, Movie> _movieCache = {};

  // Getters
  bool get isInitialized => _isInitialized;
  Movie? get currentMovie =>
      _currentBatch.isNotEmpty ? _currentBatch[_currentIndex] : null;
  int get moviesRemainingInBatch => _batchSize - _currentIndex;
  int get totalActionsRecorded => _pendingActions.length;
  int get totalMovies => _allMovies.length;

  // Tüm filmleri döndür (Browse view için)
  List<Movie> getAllMovies() {
    return List.from(_allMovies);
  }

  // 1. Servisi başlat
  Future<void> initializeService() async {
    try {
      print('🚀 Batch servis başlatılıyor...');

      // Tüm filmleri yükle
      await _loadAllMovies();
      print('📚 ${_allMovies.length} film yüklendi');

      // İlk batch'i oluştur (rastgele)
      await _createInitialBatch();
      print('🎬 İlk ${_currentBatch.length} film hazırlandı');

      // İkinci batch'i arka planda hazırla
      await _prepareNextBatch();
      print('⏳ İkinci batch arka planda hazırlandı');

      _isInitialized = true;
      print('✅ Batch servis hazır!');
    } catch (e) {
      print('❌ Batch servis hatası: $e');
      throw e;
    }
  }

  // 2. Tüm filmleri yükle
  Future<void> _loadAllMovies() async {
    final String jsonString = await rootBundle.loadString(
      'assets/movies_database.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);

    _allMovies = jsonList.map((json) => Movie.fromJson(json)).toList();

    if (_allMovies.isEmpty) {
      throw Exception('Film veritabanı boş!');
    }
  }

  // 3. İlk batch'i oluştur (rastgele)
  Future<void> _createInitialBatch() async {
    final random = Random();
    final shuffledMovies = List<Movie>.from(_allMovies)..shuffle(random);

    _currentBatch = shuffledMovies.take(_batchSize).toList();
    _currentIndex = 0;

    print('🎲 İlk batch rastgele oluşturuldu');
  }

  // 4. Sonraki batch'i akıllı şekilde hazırla
  Future<void> _prepareNextBatch() async {
    if (_isPreparingNextBatch) return;

    _isPreparingNextBatch = true;

    try {
      if (_pendingActions.length >= 5) {
        // Yeterli veri var, akıllı öneri yap
        _nextBatch = await _generateSmartBatch();
        print('🧠 Akıllı batch hazırlandı');
      } else {
        // Yeterli veri yok, çeşitli türlerden seç
        _nextBatch = await _generateDiverseBatch();
        print('🎭 Çeşitli batch hazırlandı');
      }
    } catch (e) {
      print('⚠️ Batch hazırlama hatası: $e');
      // Fallback: rastgele batch
      _nextBatch = await _generateRandomBatch();
    }

    _isPreparingNextBatch = false;
  }

  // 5. Akıllı batch oluştur
  Future<List<Movie>> _generateSmartBatch() async {
    // Kullanıcı tercihlerini analiz et
    _analyzeUserPreferences();

    // Skorlama sistemini kullanarak film seç
    List<MovieScore> scoredMovies = [];

    for (Movie movie in _allMovies) {
      // Daha önce gösterilmiş filmleri atla
      if (_hasMovieBeenShown(movie)) continue;

      double score = _calculateMovieScore(movie);
      scoredMovies.add(MovieScore(movie, score));
    }

    // Skora göre sırala
    scoredMovies.sort((a, b) => b.score.compareTo(a.score));

    // En iyi skorlu 10 filmi al (biraz çeşitlilik için)
    List<Movie> smartBatch = [];

    // İlk 7 film en yüksek skorlu
    smartBatch.addAll(scoredMovies.take(7).map((ms) => ms.movie));

    // Son 3 film keşif için (medium score)
    int midPoint = (scoredMovies.length * 0.4).round();
    smartBatch.addAll(
      scoredMovies.skip(midPoint).take(3).map((ms) => ms.movie),
    );

    return smartBatch;
  }

  // 6. Çeşitli batch oluştur (ilk kullanımlar için)
  Future<List<Movie>> _generateDiverseBatch() async {
    List<Movie> diverseBatch = [];

    // Farklı türlerden film seç
    List<String> popularGenres = [
      'Action',
      'Comedy',
      'Drama',
      'Science Fiction',
      'Romance',
      'Horror',
      'Adventure',
      'Fantasy',
    ];

    for (String genre in popularGenres.take(8)) {
      Movie? movie = _findRandomMovieByGenre(genre);
      if (movie != null && !_hasMovieBeenShown(movie)) {
        diverseBatch.add(movie);
      }
    }

    // Eksik olanları rastgele doldur
    while (diverseBatch.length < _batchSize) {
      Movie randomMovie = _getRandomUnshownMovie();
      if (!diverseBatch.contains(randomMovie)) {
        diverseBatch.add(randomMovie);
      }
    }

    return diverseBatch;
  }

  // 7. Rastgele batch oluştur (fallback)
  Future<List<Movie>> _generateRandomBatch() async {
    final random = Random();
    List<Movie> unshownMovies =
        _allMovies.where((movie) => !_hasMovieBeenShown(movie)).toList();

    unshownMovies.shuffle(random);
    return unshownMovies.take(_batchSize).toList();
  }

  // 8. Kullanıcı eylemini kaydet
  void recordUserAction(Movie movie, SwipeAction action) {
    _pendingActions.add(
      UserAction(movie: movie, action: action, timestamp: DateTime.now()),
    );

    print('📝 Eylem kaydedildi: ${movie.title} - ${action.name}');

    // 8. swipe'ta sonraki batch'i hazırlamaya başla
    if (_currentIndex == 7 && !_isPreparingNextBatch) {
      _prepareNextBatch();
      print('⚡ Sonraki batch hazırlanmaya başladı');
    }
  }

  // 9. Sonraki filme geç
  Movie? getNextMovie() {
    if (!_isInitialized || _currentBatch.isEmpty) {
      return null;
    }

    // Mevcut batch'te sonraki film
    if (_currentIndex < _currentBatch.length - 1) {
      _currentIndex++;
      return _currentBatch[_currentIndex];
    }

    // Batch bitti, yeni batch'e geç
    return _switchToNextBatch();
  }

  // 10. Yeni batch'e geç
  Movie? _switchToNextBatch() {
    if (_nextBatch.isEmpty) {
      print('⚠️ Sonraki batch hazır değil, rastgele film veriliyor');
      return _getRandomUnshownMovie();
    }

    // Batch analizi yap
    _performBatchAnalysis();

    // Batch'leri değiştir
    _currentBatch = List.from(_nextBatch);
    _nextBatch.clear();
    _currentIndex = 0;

    // Yeni sonraki batch'i hazırla
    _prepareNextBatch();

    print('🔄 Yeni batch\'e geçildi (${_currentBatch.length} film)');
    return _currentBatch.first;
  }

  // 11. Batch analizi yap
  void _performBatchAnalysis() {
    if (_pendingActions.length < 5) return;

    print('\n📊 BATCH ANALİZİ (${_pendingActions.length} eylem)');

    // Son 10 eylemi analiz et
    List<UserAction> recentActions = _pendingActions.take(10).toList();

    Map<String, int> genreStats = {};
    Map<String, int> directorStats = {};
    int likes = 0;
    int dislikes = 0;

    for (UserAction action in recentActions) {
      if (action.action == SwipeAction.like) {
        likes++;
        // Beğenilen film özelliklerini say
        for (String genre in action.movie.genre) {
          genreStats[genre] = (genreStats[genre] ?? 0) + 1;
        }
        directorStats[action.movie.director] =
            (directorStats[action.movie.director] ?? 0) + 1;
      } else {
        dislikes++;
      }
    }

    print('👍 Beğeni: $likes, 👎 Beğenmeme: $dislikes');
    print(
      '🎭 Popüler türler: ${genreStats.entries.take(3).map((e) => "${e.key}(${e.value})").join(", ")}',
    );
    print(
      '🎬 Popüler yönetmenler: ${directorStats.entries.take(2).map((e) => "${e.key}(${e.value})").join(", ")}',
    );

    // Tercihleri temizle (memory management)
    if (_pendingActions.length > 20) {
      _pendingActions = _pendingActions.take(20).toList();
    }
  }

  // 12. Kullanıcı tercihlerini analiz et
  void _analyzeUserPreferences() {
    _userPreferences.clear();

    // Son eylemlerden tercihleri çıkar
    Map<String, double> genreWeights = {};
    Map<String, double> directorWeights = {};
    Map<String, double> yearWeights = {};

    for (UserAction action in _pendingActions) {
      double actionWeight = action.action == SwipeAction.like ? 1.0 : -0.5;

      // Zaman ağırlığı (yeni eylemler daha önemli)
      Duration timeDiff = DateTime.now().difference(action.timestamp);
      double timeWeight = 1.0 - (timeDiff.inMinutes / 1440.0).clamp(0.0, 0.5);

      double finalWeight = actionWeight * timeWeight;

      // Tür tercihleri
      for (String genre in action.movie.genre) {
        genreWeights[genre] = (genreWeights[genre] ?? 0.0) + finalWeight;
      }

      // Yönetmen tercihleri
      directorWeights[action.movie.director] =
          (directorWeights[action.movie.director] ?? 0.0) + finalWeight;

      // Yıl tercihi
      String yearRange = _getYearRange(action.movie.year);
      yearWeights[yearRange] = (yearWeights[yearRange] ?? 0.0) + finalWeight;
    }

    // Tercihleri kaydet
    genreWeights.forEach((genre, weight) {
      if (weight > 0.5) {
        _userPreferences.add(
          UserPreference(type: 'genre', value: genre, weight: weight),
        );
      }
    });

    directorWeights.forEach((director, weight) {
      if (weight > 0.5) {
        _userPreferences.add(
          UserPreference(type: 'director', value: director, weight: weight),
        );
      }
    });

    yearWeights.forEach((yearRange, weight) {
      if (weight > 0.5) {
        _userPreferences.add(
          UserPreference(type: 'year_range', value: yearRange, weight: weight),
        );
      }
    });
  }

  // 13. Film skorunu hesapla
  double _calculateMovieScore(Movie movie) {
    double score = 5.0; // Base score

    for (UserPreference pref in _userPreferences) {
      switch (pref.type) {
        case 'genre':
          if (movie.genre.contains(pref.value)) {
            score += pref.weight * 2.0;
          }
          break;
        case 'director':
          if (movie.director == pref.value) {
            score += pref.weight * 1.5;
          }
          break;
        case 'year_range':
          if (_getYearRange(movie.year) == pref.value) {
            score += pref.weight * 1.0;
          }
          break;
      }
    }

    // Film kalitesi bonusu
    score += movie.genre.length * 0.1; // Çoklu tür bonusu
    score += movie.cast.length * 0.05; // Cast bonusu

    // Yıl bonusu (yeni filmler hafif avantajlı)
    if (movie.year > 2015) score += 0.5;
    if (movie.year > 2020) score += 0.3;

    return score;
  }

  // Yardımcı fonksiyonlar
  bool _hasMovieBeenShown(Movie movie) {
    return _currentBatch.any((m) => m.id == movie.id) ||
        _pendingActions.any((action) => action.movie.id == movie.id);
  }

  Movie? _findRandomMovieByGenre(String genre) {
    List<Movie> genreMovies =
        _allMovies
            .where(
              (movie) =>
                  movie.genre.contains(genre) && !_hasMovieBeenShown(movie),
            )
            .toList();

    if (genreMovies.isEmpty) return null;

    final random = Random();
    return genreMovies[random.nextInt(genreMovies.length)];
  }

  Movie _getRandomUnshownMovie() {
    List<Movie> unshownMovies =
        _allMovies.where((movie) => !_hasMovieBeenShown(movie)).toList();

    if (unshownMovies.isEmpty) {
      // Tüm filmler gösterildi, baştan başla
      return _allMovies[Random().nextInt(_allMovies.length)];
    }

    return unshownMovies[Random().nextInt(unshownMovies.length)];
  }

  String _getYearRange(int year) {
    if (year >= 2020) return '2020s';
    if (year >= 2010) return '2010s';
    if (year >= 2000) return '2000s';
    if (year >= 1990) return '1990s';
    return 'Classic';
  }

  // Debug fonksiyonlar
  void printBatchStatus() {
    print('\n🔍 BATCH DURUMU:');
    print('Mevcut batch: ${_currentIndex + 1}/${_currentBatch.length}');
    print('Sonraki batch hazır: ${_nextBatch.isNotEmpty}');
    print('Toplam eylem: ${_pendingActions.length}');
    print('Kullanıcı tercihleri: ${_userPreferences.length}');
  }

  void printUserPreferences() {
    print('\n👤 KULLANICI TERCİHLERİ:');
    if (_userPreferences.isEmpty) {
      print('Henüz tercih analizi yapılmadı');
      return;
    }

    for (UserPreference pref in _userPreferences) {
      print(
        '${pref.type}: ${pref.value} (ağırlık: ${pref.weight.toStringAsFixed(1)})',
      );
    }
  }

  // Watchlist'teki filmleri mevcut batch'ten filtrele
  Future<void> filterWatchlistMovies(List<String> watchlistMovieIds) async {
    if (watchlistMovieIds.isEmpty) return;

    print('🔍 Filtreleme öncesi:');
    print('  - Tüm filmler: ${_allMovies.length}');
    print('  - Mevcut batch: ${_currentBatch.length}');
    print('  - Sonraki batch: ${_nextBatch.length}');
    print('  - Watchlist IDs: $watchlistMovieIds');

    final originalMovieCount = _allMovies.length;

    // Önce _allMovies listesinden watchlist'teki filmleri çıkar
    _allMovies.removeWhere(
      (movie) => watchlistMovieIds.contains(movie.id.toString()),
    );

    // Mevcut batch'ten watchlist'teki filmleri çıkar
    _currentBatch.removeWhere(
      (movie) => watchlistMovieIds.contains(movie.id.toString()),
    );

    // Sonraki batch'ten de çıkar
    _nextBatch.removeWhere(
      (movie) => watchlistMovieIds.contains(movie.id.toString()),
    );

    // Eğer çok fazla film filtrelendiyse uyarı ver
    final filteredCount = watchlistMovieIds.length;
    final remainingMovies = _allMovies.length;

    if (filteredCount > originalMovieCount * 0.8) {
      print('⚠️ DİKKAT: Çok fazla film filtrelendi!');
      print('  - Filtrelenen: $filteredCount film');
      print('  - Kalan: $remainingMovies film');
      print('  - Bu kullanıcı çoğu filmi beğenmiş.');
    }

    // Eğer mevcut batch boşaldıysa, yeni batch oluştur
    if (_currentBatch.isEmpty && _allMovies.isNotEmpty) {
      print('📝 Mevcut batch boş, yeni batch oluşturuluyor...');
      _currentBatch = await _generateRandomBatch();
      _currentIndex = 0;
    }

    // Eğer sonraki batch boşaldıysa, yeni batch hazırla
    if (_nextBatch.isEmpty && _allMovies.isNotEmpty) {
      print('📝 Sonraki batch boş, yeni batch hazırlanıyor...');
      _nextBatch = await _generateRandomBatch();
    }

    print('🚫 Filtreleme sonrası:');
    print('  - Tüm filmler: ${_allMovies.length}');
    print('  - Mevcut batch: ${_currentBatch.length}');
    print('  - Sonraki batch: ${_nextBatch.length}');
    print('  - ${watchlistMovieIds.length} watchlist filmi filtrelendi');
  }

  // Mevcut class'ın içine bu metodu ekleyin:
  Future<Movie?> getMovieById(int movieId) async {
    try {
      // Cache'de kontrol et
      if (_movieCache.containsKey(movieId)) {
        return _movieCache[movieId];
      }

      // JSON'dan yükle
      if (_allMovies.isEmpty) {
        await _loadAllMovies();
      }

      final movie = _allMovies.firstWhere(
        (m) => m.id == movieId,
        orElse: () => throw Exception('Movie not found'),
      );

      // Cache'e ekle
      _movieCache[movieId] = movie;
      return movie;
    } catch (e) {
      print('Error getting movie by ID $movieId: $e');
      return null;
    }
  }
}

// Yardımcı sınıflar
class MovieScore {
  final Movie movie;
  final double score;

  MovieScore(this.movie, this.score);
}
