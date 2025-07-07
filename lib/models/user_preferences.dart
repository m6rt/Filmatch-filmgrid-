import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static SharedPreferences? _prefs;
  
  // Başlatma
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Beğenilen film ekle
  static Future<void> addLikedMovie(String imdbId, String title, String genre, String director, String actors) async {
    List<String> likedMovies = getLikedMovies();
    if (!likedMovies.contains(imdbId)) {
      likedMovies.add(imdbId);
      await _prefs!.setStringList('liked_movies', likedMovies);
    }
    
    // Tür tercihleri güncelle
    await _updateGenrePreferences(genre, isLiked: true);
    
    // Yönetmen tercihleri güncelle
    await _updateDirectorPreferences(director, isLiked: true);
    
    // Oyuncu tercihleri güncelle
    await _updateActorPreferences(actors, isLiked: true);
    
    print('✅ Liked: $title - Genre: $genre - Director: $director');
  }

  // Beğenilmeyen film ekle
  static Future<void> addDislikedMovie(String imdbId, String title, String genre, String director, String actors) async {
    List<String> dislikedMovies = getDislikedMovies();
    if (!dislikedMovies.contains(imdbId)) {
      dislikedMovies.add(imdbId);
      await _prefs!.setStringList('disliked_movies', dislikedMovies);
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
  static Future<void> _updateGenrePreferences(String genres, {required bool isLiked}) async {
    Map<String, int> genreScores = _getPreferenceScores('genre_scores');
    
    List<String> genreList = genres.split(',').map((g) => g.trim()).toList();
    
    for (String genre in genreList) {
      if (genre.isNotEmpty) {
        int currentScore = genreScores[genre] ?? 0;
        genreScores[genre] = isLiked ? currentScore + 1 : currentScore - 1;
      }
    }
    
    await _savePreferenceScores('genre_scores', genreScores);
  }

  // Yönetmen tercihlerini güncelle
  static Future<void> _updateDirectorPreferences(String directors, {required bool isLiked}) async {
    Map<String, int> directorScores = _getPreferenceScores('director_scores');
    
    List<String> directorList = directors.split(',').map((d) => d.trim()).toList();
    
    for (String director in directorList) {
      if (director.isNotEmpty && director != 'N/A' && director != 'Unknown') {
        int currentScore = directorScores[director] ?? 0;
        directorScores[director] = isLiked ? currentScore + 1 : currentScore - 1;
      }
    }
    
    await _savePreferenceScores('director_scores', directorScores);
  }

  // Oyuncu tercihlerini güncelle
  static Future<void> _updateActorPreferences(String actors, {required bool isLiked}) async {
    Map<String, int> actorScores = _getPreferenceScores('actor_scores');
    
    List<String> actorList = actors.split(',').map((a) => a.trim()).toList();
    
    for (String actor in actorList.take(3)) { // Sadece ilk 3 oyuncu
      if (actor.isNotEmpty && actor != 'N/A' && actor != 'Unknown') {
        int currentScore = actorScores[actor] ?? 0;
        actorScores[actor] = isLiked ? currentScore + 1 : currentScore - 1;
      }
    }
    
    await _savePreferenceScores('actor_scores', actorScores);
  }

  // Tercih puanlarını al
  static Map<String, int> _getPreferenceScores(String key) {
    List<String> preferenceList = _prefs!.getStringList(key) ?? [];
    Map<String, int> scores = {};
    
    for (String item in preferenceList) {
      List<String> parts = item.split(':::');
      if (parts.length == 2) {
        scores[parts[0]] = int.parse(parts[1]);
      }
    }
    
    return scores;
  }

  // Tercih puanlarını kaydet
  static Future<void> _savePreferenceScores(String key, Map<String, int> scores) async {
    List<String> preferenceList = [];
    scores.forEach((name, score) {
      preferenceList.add('$name:::$score');
    });
    
    await _prefs!.setStringList(key, preferenceList);
  }

  // En çok beğenilen türleri al
  static List<String> getPreferredGenres() {
    Map<String, int> genreScores = _getPreferenceScores('genre_scores');
    
    List<MapEntry<String, int>> sortedEntries = genreScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .where((entry) => entry.value > 0)
        .take(5)
        .map((entry) => entry.key)
        .toList();
  }

  // En çok beğenilen yönetmenleri al
  static List<String> getPreferredDirectors() {
    Map<String, int> directorScores = _getPreferenceScores('director_scores');
    
    List<MapEntry<String, int>> sortedEntries = directorScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .where((entry) => entry.value > 0)
        .take(3)
        .map((entry) => entry.key)
        .toList();
  }

  // En çok beğenilen oyuncuları al
  static List<String> getPreferredActors() {
    Map<String, int> actorScores = _getPreferenceScores('actor_scores');
    
    List<MapEntry<String, int>> sortedEntries = actorScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .where((entry) => entry.value > 0)
        .take(3)
        .map((entry) => entry.key)
        .toList();
  }

  // Listeler
  static List<String> getLikedMovies() {
    return _prefs!.getStringList('liked_movies') ?? [];
  }

  static List<String> getDislikedMovies() {
    return _prefs!.getStringList('disliked_movies') ?? [];
  }

  // Tercihleri temizle
  static Future<void> clearPreferences() async {
    await _prefs!.clear();
  }

  // Algoritma istatistikleri
  static Map<String, dynamic> getAlgorithmStats() {
    return {
      'liked_movies_count': getLikedMovies().length,
      'disliked_movies_count': getDislikedMovies().length,
      'preferred_genres': getPreferredGenres(),
      'preferred_directors': getPreferredDirectors(),
      'preferred_actors': getPreferredActors(),
    };
  }
}