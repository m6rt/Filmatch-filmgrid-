import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static SharedPreferences? _prefs;

  // Başlatma
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // SharedPreferences instance'ını al
  static Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // Beğenilen film ekle (eski format - 3 parametre)
  static Future<void> addLikedMovie(
    String genre,
    String director,
    String actors,
  ) async {
    final prefs = await _getPrefs();

    // Tür tercihleri güncelle
    await _updateGenrePreferences(genre, isLiked: true);

    // Yönetmen tercihleri güncelle
    await _updateDirectorPreferences(director, isLiked: true);

    // Oyuncu tercihleri güncelle
    await _updateActorPreferences(actors, isLiked: true);

    print('✅ Liked - Genre: $genre - Director: $director');
  }

  // Beğenilmeyen film ekle (eski format - 3 parametre)
  static Future<void> addDislikedMovie(
    String genre,
    String director,
    String actors,
  ) async {
    final prefs = await _getPrefs();

    // Tür tercihleri güncelle
    await _updateGenrePreferences(genre, isLiked: false);

    // Yönetmen tercihleri güncelle
    await _updateDirectorPreferences(director, isLiked: false);

    // Oyuncu tercihleri güncelle
    await _updateActorPreferences(actors, isLiked: false);

    print('❌ Disliked - Genre: $genre - Director: $director');
  }

  // Beğenilen film ekle (yeni format - 5 parametre)
  static Future<void> addLikedMovieWithId(
    String imdbId,
    String title,
    String genre,
    String director,
    String actors,
  ) async {
    final prefs = await _getPrefs();

    List<String> likedMovies = await getLikedMovieIds();
    if (!likedMovies.contains(imdbId)) {
      likedMovies.add(imdbId);
      await prefs.setStringList('liked_movies', likedMovies);
    }

    // Tür tercihleri güncelle
    await _updateGenrePreferences(genre, isLiked: true);

    // Yönetmen tercihleri güncelle
    await _updateDirectorPreferences(director, isLiked: true);

    // Oyuncu tercihleri güncelle
    await _updateActorPreferences(actors, isLiked: true);

    print('✅ Liked: $title - Genre: $genre - Director: $director');
  }

  // Beğenilmeyen film ekle (yeni format - 5 parametre)
  static Future<void> addDislikedMovieWithId(
    String imdbId,
    String title,
    String genre,
    String director,
    String actors,
  ) async {
    final prefs = await _getPrefs();

    List<String> dislikedMovies = await getDislikedMovieIds();
    if (!dislikedMovies.contains(imdbId)) {
      dislikedMovies.add(imdbId);
      await prefs.setStringList('disliked_movies', dislikedMovies);
    }

    // Tür tercihleri güncelle
    await _updateGenrePreferences(genre, isLiked: false);

    // Yönetmen tercihleri güncelle
    await _updateDirectorPreferences(director, isLiked: false);

    // Oyuncu tercihleri güncelle
    await _updateActorPreferences(actors, isLiked: false);

    print('❌ Disliked: $title - Genre: $genre - Director: $director');
  }

  // Tür tercihlerini güncelle
  static Future<void> _updateGenrePreferences(
    String genres, {
    required bool isLiked,
  }) async {
    Map<String, int> genreScores = await _getPreferenceScores('genre_scores');

    List<String> genreList = genres.split(',').map((g) => g.trim()).toList();

    for (String genre in genreList) {
      if (genre.isNotEmpty && genre != 'N/A' && genre != 'Unknown') {
        int currentScore = genreScores[genre] ?? 0;
        genreScores[genre] = isLiked ? currentScore + 1 : currentScore - 1;
      }
    }

    await _savePreferenceScores('genre_scores', genreScores);
  }

  // Yönetmen tercihlerini güncelle
  static Future<void> _updateDirectorPreferences(
    String directors, {
    required bool isLiked,
  }) async {
    Map<String, int> directorScores = await _getPreferenceScores(
      'director_scores',
    );

    List<String> directorList =
        directors.split(',').map((d) => d.trim()).toList();

    for (String director in directorList) {
      if (director.isNotEmpty && director != 'N/A' && director != 'Unknown') {
        int currentScore = directorScores[director] ?? 0;
        directorScores[director] =
            isLiked ? currentScore + 1 : currentScore - 1;
      }
    }

    await _savePreferenceScores('director_scores', directorScores);
  }

  // Oyuncu tercihlerini güncelle
  static Future<void> _updateActorPreferences(
    String actors, {
    required bool isLiked,
  }) async {
    Map<String, int> actorScores = await _getPreferenceScores('actor_scores');

    List<String> actorList = actors.split(',').map((a) => a.trim()).toList();

    for (String actor in actorList.take(5)) {
      // İlk 5 oyuncu
      if (actor.isNotEmpty && actor != 'N/A' && actor != 'Unknown') {
        int currentScore = actorScores[actor] ?? 0;
        actorScores[actor] = isLiked ? currentScore + 1 : currentScore - 1;
      }
    }

    await _savePreferenceScores('actor_scores', actorScores);
  }

  // Tercih puanlarını al
  static Future<Map<String, int>> _getPreferenceScores(String key) async {
    final prefs = await _getPrefs();
    List<String> preferenceList = prefs.getStringList(key) ?? [];
    Map<String, int> scores = {};

    for (String item in preferenceList) {
      List<String> parts = item.split(':::');
      if (parts.length == 2) {
        scores[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }

    return scores;
  }

  // Tercih puanlarını kaydet
  static Future<void> _savePreferenceScores(
    String key,
    Map<String, int> scores,
  ) async {
    final prefs = await _getPrefs();
    List<String> preferenceList = [];
    scores.forEach((name, score) {
      if (score != 0) {
        // Sadece 0 olmayan puanları kaydet
        preferenceList.add('$name:::$score');
      }
    });

    await prefs.setStringList(key, preferenceList);
  }

  // ✅ RecommendationService için gerekli metodlar

  // Beğenilen türleri al
  static Future<List<String>> getLikedGenres() async {
    Map<String, int> genreScores = await _getPreferenceScores('genre_scores');

    List<MapEntry<String, int>> sortedEntries =
        genreScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .where((entry) => entry.value > 0)
        .take(10)
        .map((entry) => entry.key)
        .toList();
  }

  // Beğenilen yönetmenleri al
  static Future<List<String>> getLikedDirectors() async {
    Map<String, int> directorScores = await _getPreferenceScores(
      'director_scores',
    );

    List<MapEntry<String, int>> sortedEntries =
        directorScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .where((entry) => entry.value > 0)
        .take(5)
        .map((entry) => entry.key)
        .toList();
  }

  // Beğenilen oyuncuları al
  static Future<List<String>> getLikedActors() async {
    Map<String, int> actorScores = await _getPreferenceScores('actor_scores');

    List<MapEntry<String, int>> sortedEntries =
        actorScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .where((entry) => entry.value > 0)
        .take(10)
        .map((entry) => entry.key)
        .toList();
  }

  // Beğenilmeyen türleri al
  static Future<List<String>> getDislikedGenres() async {
    Map<String, int> genreScores = await _getPreferenceScores('genre_scores');

    List<MapEntry<String, int>> sortedEntries =
        genreScores.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    return sortedEntries
        .where((entry) => entry.value < 0)
        .take(5)
        .map((entry) => entry.key)
        .toList();
  }

  // Beğenilmeyen yönetmenleri al
  static Future<List<String>> getDislikedDirectors() async {
    Map<String, int> directorScores = await _getPreferenceScores(
      'director_scores',
    );

    List<MapEntry<String, int>> sortedEntries =
        directorScores.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    return sortedEntries
        .where((entry) => entry.value < 0)
        .take(3)
        .map((entry) => entry.key)
        .toList();
  }

  // Beğenilmeyen oyuncuları al
  static Future<List<String>> getDislikedActors() async {
    Map<String, int> actorScores = await _getPreferenceScores('actor_scores');

    List<MapEntry<String, int>> sortedEntries =
        actorScores.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    return sortedEntries
        .where((entry) => entry.value < 0)
        .take(5)
        .map((entry) => entry.key)
        .toList();
  }

  // Beğenilen filmlerin genel bilgilerini al (eski format için)
  static Future<Map<String, dynamic>> getLikedMovies() async {
    List<String> genres = await getLikedGenres();
    List<String> directors = await getLikedDirectors();
    List<String> actors = await getLikedActors();

    return {'genres': genres, 'directors': directors, 'cast': actors};
  }

  // Beğenilmeyen filmlerin genel bilgilerini al (eski format için)
  static Future<Map<String, dynamic>> getDislikedMovies() async {
    List<String> genres = await getDislikedGenres();
    List<String> directors = await getDislikedDirectors();
    List<String> actors = await getDislikedActors();

    return {'genres': genres, 'directors': directors, 'cast': actors};
  }

  // Film ID listelerini al
  static Future<List<String>> getLikedMovieIds() async {
    final prefs = await _getPrefs();
    return prefs.getStringList('liked_movies') ?? [];
  }

  static Future<List<String>> getDislikedMovieIds() async {
    final prefs = await _getPrefs();
    return prefs.getStringList('disliked_movies') ?? [];
  }

  // En çok beğenilen türleri al (geriye dönük uyumluluk)
  static Future<List<String>> getPreferredGenres() async {
    return await getLikedGenres();
  }

  // En çok beğenilen yönetmenleri al (geriye dönük uyumluluk)
  static Future<List<String>> getPreferredDirectors() async {
    return await getLikedDirectors();
  }

  // En çok beğenilen oyuncuları al (geriye dönük uyumluluk)
  static Future<List<String>> getPreferredActors() async {
    return await getLikedActors();
  }

  // Kullanıcının film tercihi var mı?
  static Future<bool> hasPreferences() async {
    List<String> likedGenres = await getLikedGenres();
    List<String> likedDirectors = await getLikedDirectors();

    return likedGenres.isNotEmpty || likedDirectors.isNotEmpty;
  }

  // Bir türün puanını al
  static Future<int> getGenreScore(String genre) async {
    Map<String, int> genreScores = await _getPreferenceScores('genre_scores');
    return genreScores[genre] ?? 0;
  }

  // Bir yönetmenin puanını al
  static Future<int> getDirectorScore(String director) async {
    Map<String, int> directorScores = await _getPreferenceScores(
      'director_scores',
    );
    return directorScores[director] ?? 0;
  }

  // Bir oyuncunun puanını al
  static Future<int> getActorScore(String actor) async {
    Map<String, int> actorScores = await _getPreferenceScores('actor_scores');
    return actorScores[actor] ?? 0;
  }

  // Tüm puanları al (debug için)
  static Future<Map<String, dynamic>> getAllScores() async {
    return {
      'genre_scores': await _getPreferenceScores('genre_scores'),
      'director_scores': await _getPreferenceScores('director_scores'),
      'actor_scores': await _getPreferenceScores('actor_scores'),
    };
  }

  // Tercihleri temizle
  static Future<void> clearPreferences() async {
    final prefs = await _getPrefs();
    await prefs.clear();
    print('🗑️ All preferences cleared');
  }

  // Belirli bir kategoriyi temizle
  static Future<void> clearGenrePreferences() async {
    final prefs = await _getPrefs();
    await prefs.remove('genre_scores');
  }

  static Future<void> clearDirectorPreferences() async {
    final prefs = await _getPrefs();
    await prefs.remove('director_scores');
  }

  static Future<void> clearActorPreferences() async {
    final prefs = await _getPrefs();
    await prefs.remove('actor_scores');
  }

  // Algoritma istatistikleri
  static Future<Map<String, dynamic>> getAlgorithmStats() async {
    List<String> likedMovieIds = await getLikedMovieIds();
    List<String> dislikedMovieIds = await getDislikedMovieIds();
    List<String> preferredGenres = await getPreferredGenres();
    List<String> preferredDirectors = await getPreferredDirectors();
    List<String> preferredActors = await getPreferredActors();

    return {
      'liked_movies_count': likedMovieIds.length,
      'disliked_movies_count': dislikedMovieIds.length,
      'preferred_genres': preferredGenres,
      'preferred_directors': preferredDirectors,
      'preferred_actors': preferredActors,
      'has_preferences': await hasPreferences(),
      'total_interactions': likedMovieIds.length + dislikedMovieIds.length,
    };
  }

  // Tercihleri export et (backup için)
  static Future<Map<String, dynamic>> exportPreferences() async {
    final prefs = await _getPrefs();
    return {
      'liked_movies': prefs.getStringList('liked_movies') ?? [],
      'disliked_movies': prefs.getStringList('disliked_movies') ?? [],
      'genre_scores': prefs.getStringList('genre_scores') ?? [],
      'director_scores': prefs.getStringList('director_scores') ?? [],
      'actor_scores': prefs.getStringList('actor_scores') ?? [],
      'export_date': DateTime.now().toIso8601String(),
    };
  }

  // Tercihleri import et (restore için)
  static Future<void> importPreferences(Map<String, dynamic> data) async {
    final prefs = await _getPrefs();

    if (data['liked_movies'] != null) {
      await prefs.setStringList(
        'liked_movies',
        List<String>.from(data['liked_movies']),
      );
    }

    if (data['disliked_movies'] != null) {
      await prefs.setStringList(
        'disliked_movies',
        List<String>.from(data['disliked_movies']),
      );
    }

    if (data['genre_scores'] != null) {
      await prefs.setStringList(
        'genre_scores',
        List<String>.from(data['genre_scores']),
      );
    }

    if (data['director_scores'] != null) {
      await prefs.setStringList(
        'director_scores',
        List<String>.from(data['director_scores']),
      );
    }

    if (data['actor_scores'] != null) {
      await prefs.setStringList(
        'actor_scores',
        List<String>.from(data['actor_scores']),
      );
    }

    print('📥 Preferences imported successfully');
  }
}
