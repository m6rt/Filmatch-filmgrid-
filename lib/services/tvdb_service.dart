import 'package:http/http.dart' as http;
import 'dart:convert';

class TVDBService {
  static const String _baseUrl = 'https://api4.thetvdb.com/v4';
  static const String _apiKey = 'YOUR_TVDB_API_KEY';
  static String? _token;

  // Token al
  static Future<void> _getToken() async {
    if (_token != null) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'apikey': _apiKey}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['data']['token'];
        print('✅ TVDB Token obtained');
      }
    } catch (e) {
      print('❌ Error getting TVDB token: $e');
    }
  }

  // Türe göre film ara
  static Future<List<Map<String, dynamic>>> searchMoviesByGenre(String genre) async {
    await _getToken();
    if (_token == null) return [];

    List<Map<String, dynamic>> movies = [];
    
    try {
      // Türe göre arama
      final response = await http.get(
        Uri.parse('$_baseUrl/search?query=$genre&type=movie&limit=20'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          for (var item in data['data']) {
            if (item['type'] == 'movie') {
              Map<String, dynamic>? movieDetails = await getMovieDetails(item['tvdb_id'].toString());
              if (movieDetails != null) {
                movies.add(movieDetails);
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error searching movies by genre: $e');
    }

    return movies;
  }

  // Popüler filmler
  static Future<List<Map<String, dynamic>>> getPopularMovies() async {
    await _getToken();
    if (_token == null) return [];

    List<Map<String, dynamic>> movies = [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movies/popular?limit=30'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          for (var movie in data['data']) {
            Map<String, dynamic>? movieDetails = await getMovieDetails(movie['id'].toString());
            if (movieDetails != null) {
              movies.add(movieDetails);
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error getting popular movies: $e');
    }

    return movies;
  }

  // En çok oy alan filmler
  static Future<List<Map<String, dynamic>>> getTopRatedMovies() async {
    await _getToken();
    if (_token == null) return [];

    List<Map<String, dynamic>> movies = [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movies/top-rated?limit=20'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          for (var movie in data['data']) {
            Map<String, dynamic>? movieDetails = await getMovieDetails(movie['id'].toString());
            if (movieDetails != null) {
              movies.add(movieDetails);
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error getting top rated movies: $e');
    }

    return movies;
  }

  // Yeni filmler
  static Future<List<Map<String, dynamic>>> getLatestMovies() async {
    await _getToken();
    if (_token == null) return [];

    List<Map<String, dynamic>> movies = [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movies/latest?limit=25'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          for (var movie in data['data']) {
            Map<String, dynamic>? movieDetails = await getMovieDetails(movie['id'].toString());
            if (movieDetails != null) {
              movies.add(movieDetails);
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error getting latest movies: $e');
    }

    return movies;
  }

  // Benzer filmler
  static Future<List<Map<String, dynamic>>> getSimilarMovies(String movieId) async {
    await _getToken();
    if (_token == null) return [];

    List<Map<String, dynamic>> movies = [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movies/$movieId/similar?limit=15'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          for (var movie in data['data']) {
            Map<String, dynamic>? movieDetails = await getMovieDetails(movie['id'].toString());
            if (movieDetails != null) {
              movies.add(movieDetails);
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error getting similar movies: $e');
    }

    return movies;
  }

  // Arama
  static Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    await _getToken();
    if (_token == null) return [];

    List<Map<String, dynamic>> movies = [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?query=${Uri.encodeComponent(query)}&type=movie&limit=20'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          for (var item in data['data']) {
            if (item['type'] == 'movie') {
              Map<String, dynamic>? movieDetails = await getMovieDetails(item['tvdb_id'].toString());
              if (movieDetails != null) {
                movies.add(movieDetails);
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error searching movies: $e');
    }

    return movies;
  }

  // Film detayları
  static Future<Map<String, dynamic>?> getMovieDetails(String movieId) async {
    await _getToken();
    if (_token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movies/$movieId/extended'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return _convertToStandardFormat(data['data']);
        }
      }
    } catch (e) {
      print('❌ Error getting movie details: $e');
    }

    return null;
  }

  // Türler listesi
  static Future<List<String>> getGenres() async {
    await _getToken();
    if (_token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/genres'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return List<String>.from(data['data'].map((genre) => genre['name']));
        }
      }
    } catch (e) {
      print('❌ Error getting genres: $e');
    }

    return [];
  }

  // YouTube trailer URL'si
  static String? getYouTubeTrailerKey(String movieTitle, String year) {
    Map<String, String> trailerKeys = {
      // 2024 Filmleri
      'Dune: Part Two': 'Way9Dexny3w',
      'Deadpool & Wolverine': 'inJgHGq5lrw',
      'Inside Out 2': 'LEjhY15eCx0',
      'Beetlejuice Beetlejuice': 'CoZqL0QI1vI',
      'Wicked': 'B4gotQi6-L8',
      'Moana 2': 'hDZ7y8RP5HE',
      'A Quiet Place: Day One': 'YPY7J-flzE8',
      'Alien: Romulus': 'x0XDEhP4MQs',
      'The Wild Robot': 'pVYV6SgIqE8',
      'Gladiator II': 'qOVWFrXYfnE',
      
      // 2023 Filmleri
      'Oppenheimer': 'uYPbbksJxIg',
      'Barbie': 'pBk4NYhWNMM',
      'Guardians of the Galaxy Vol. 3': 'u3V5KDHRQvk',
      'Spider-Man: Across the Spider-Verse': 'cqGjhVJWtEg',
      'The Flash': 'hebWYacbdvc',
      'Transformers: Rise of the Beasts': 'itnqEauWQZM',
      'Indiana Jones and the Dial of Destiny': 'eQfMbSe7F2g',
      'Mission: Impossible – Dead Reckoning Part One': 'avz06PDqDbM',
      'John Wick: Chapter 4': 'qEVUtrk8_B4',
      'Scream VI': 'h74AXqw4Opc',
      'The Super Mario Bros. Movie': 'TnGl01FkMMo',
      'Fast X': 'eoOaKN4qCKw',
      'Air': 'Euy4yIjRzfc',
      'Cocaine Bear': 'DuKaJLc-5nA',
      'Creed III': 'AHmCH7iB_IM',
      'Ant-Man and the Wasp: Quantumania': 'ZlNFpri-Y40',
      'Avatar: The Way of Water': 'o5F8MOz_IDM',
      
      // 2022 Filmleri
      'Top Gun: Maverick': 'qSqVVswa420',
      'Black Panther: Wakanda Forever': 'RlOB3UALvrQ',
      'Thor: Love and Thunder': 'tgB1wUcmbbw',
      'Jurassic World Dominion': 'fb5ELWi-ekk',
      'Doctor Strange in the Multiverse of Madness': 'aWzlQ2N6qqg',
      'Minions: The Rise of Gru': 'S86kWCJlDWs',
      'The Batman': 'mqqft2x_Aa4',
      'Uncharted': 'eHp3MbsCbMg',
      'Sonic the Hedgehog 2': 'G5kzUpWAusI',
      'Morbius': 'oZ6iiRrz1SY',
      'The Northman': 'oMSdFM12hOw',
      'Everything Everywhere All at Once': 'wxN1T1uxQ2g',
      'Turning Red': 'XdKzUbAiswE',
      'The Bad Guys': 'f6TlIXHaO4Y',
      'Fantastic Beasts: The Secrets of Dumbledore': '8bAEuX2w2Ow',
      
      // 2021 Filmleri
      'Spider-Man: No Way Home': 'JfVOs4VSpmA',
      'Eternals': 'x_me3xsvDgk',
      'Dune': '8g18jFHCLXk',
      'No Time to Die': 'BIhNsAtPbPI',
      'Fast & Furious 9': 'FUK2kdmwEjU',
      'Black Widow': 'Fp9pNPdNwjI',
      'Shang-Chi and the Legend of the Ten Rings': '8YjFbMbfXaQ',
      'Venom: Let There Be Carnage': '-FmWuCgJmxo',
      'The Matrix Resurrections': '9ix7TUGVYIo',
      'Ghostbusters: Afterlife': 'ahZFCF--uRY',
      'House of Gucci': 'pPPn33bFbI4',
      'West Side Story': 'A9DgO3ESP8s',
      'The King\'s Man': 'kj8-YUgNQeM',
      'Encanto': 'CaimKeDcudo',
      'Luca': 'mYzchHZCu0U',
      'Cruella': 'gmRKv7n2If8',
      'Godzilla vs. Kong': 'odM92ap8_c0',
      'Mortal Kombat': 'NYH2sLid0Zc',
      'The Tomorrow War': 'SKU4WsIiLvM',
      'A Quiet Place Part II': 'BpdDN9d9Jio',
      
      // Klasik Filmler
      'The Shawshank Redemption': 'NmzuHjWmXOc',
      'The Godfather': 'sY1S34973zA',
      'The Dark Knight': 'EXeTwQWrcwY',
      'Pulp Fiction': 's7EdQ4FqbhY',
      'Fight Club': 'BdJKm16Co6M',
      'Forrest Gump': 'bLvqoHBptjg',
      'Inception': 'YoHD9XEInc0',
      'The Matrix': 'vKQi3bBA1y8',
      'Goodfellas': 'qo5jJpHtI1Y',
      'Interstellar': 'zSWdZVtXT7E',
      'The Lord of the Rings: The Fellowship of the Ring': 'V75dMMIW2B4',
      'The Lord of the Rings: The Return of the King': 'r5X-hFf6Bwo',
      'Star Wars': 'vZ734NWnAHA',
      'Titanic': 'I7c1etV7D7g',
      'Gladiator': 'owK1qxDselE',
      'Saving Private Ryan': 'zwhP5b4tD6g',
      'The Lion King': '4sj1MT05lAA',
      'Jurassic Park': 'lc0UehYemOA',
      'Terminator 2: Judgment Day': 'CRRlbK5w8AE',
      'Back to the Future': 'qvsgGtivCgs',
      'Jaws': 'U1fu_sA7XhE',
      'E.T. the Extra-Terrestrial': 'qYAETtIIClk',
      'Raiders of the Lost Ark': '0ZoSYsNADtY',
      'Star Wars: The Empire Strikes Back': 'JNwNXF9Y6kY',
      'Star Wars: Return of the Jedi': 'XgB4gaY2dWE',
      'Casablanca': 'BkL9l7qovsE',
      'Gone with the Wind': 'OaYmzAx7m7E',
      'The Wizard of Oz': 'PSicdnahJ7o',
      'Citizen Kane': 'zyv19bg0scg',
      'Psycho': 'Wz719b9QUqY',
      'Vertigo': 'Z5jvQwwHQNY',
      'Sunset Boulevard': 'roc-xRgmHjE',
      'Dr. Strangelove': 'wpZ3jPMM5Ac',
      '2001: A Space Odyssey': 'Z2UWOeBcsJI',
      'Apocalypse Now': 'FTjG-Aux_yE',
      'The Treasure of the Sierra Madre': 'kHplQ6RyWPA',
      'Chinatown': 'jDQDDlGjjGY',
      'The Third Man': 'ZX22tPDjWNg',
      'Singin\' in the Rain': 'D1ZYhVpdXbQ',
      'Raging Bull': 'nTZqNbJJqqk',
      'Lawrence of Arabia': 'THTB61EOuGw',
      'Schindler\'s List': 'gG22XNhtnoY',
      'Vertigo': 'Z5jvQwwHQNY',
      'The Searchers': 'aKgNjaMr7lE',
      'Sunrise': 'J6kFnZGO_c8',
      'Touch of Evil': 'tZvlFgWP_3s',
      'The Best Years of Our Lives': 'b6gN7jSE5fU',
      'City Lights': 'w7bPwYiMO8E',
      'The Gold Rush': 'mLxc2sLfEZU',
      'Duck Soup': 'jCpFOdmm1Zg',
      'Sullivan\'s Travels': 'XY_3DwGNKwI',
      'The Great Dictator': 'J7GY1Xg6X20',
      'Buster Keaton': 'fk7qOLyEYgU',
    };

    String searchKey = movieTitle.toLowerCase();
    
    // Exact match
    for (String key in trailerKeys.keys) {
      if (key.toLowerCase() == searchKey) {
        return trailerKeys[key];
      }
    }
    
    // Partial match
    for (String key in trailerKeys.keys) {
      if (key.toLowerCase().contains(searchKey) || searchKey.contains(key.toLowerCase())) {
        return trailerKeys[key];
      }
    }
    
    return null;
  }

  // Format dönüştürme
  static Map<String, dynamic> _convertToStandardFormat(Map<String, dynamic> tvdbData) {
    List<String> genres = [];
    if (tvdbData['genres'] != null) {
      genres = List<String>.from(tvdbData['genres'].map((g) => g['name']));
    }

    return {
      'id': tvdbData['id'].toString(),
      'title': tvdbData['name'] ?? 'Unknown',
      'vote_average': _parseRating(tvdbData['score']),
      'overview': tvdbData['overview'] ?? 'No overview available',
      'poster_path': tvdbData['image'] ?? null,
      'release_date': tvdbData['first_air_date'] ?? tvdbData['release_date'] ?? 'Unknown',
      'director': _getDirector(tvdbData),
      'cast': _getCast(tvdbData),
      'runtime': tvdbData['runtime'] ?? 'Unknown',
      'year': _getYear(tvdbData),
      'genre': genres.join(', '),
      'imdb_rating': tvdbData['score']?.toString() ?? 'N/A',
      'awards': tvdbData['awards'] ?? 'N/A',
      'country': tvdbData['country'] ?? 'Unknown',
      'language': tvdbData['original_language'] ?? 'Unknown',
      'tvdb_id': tvdbData['id'].toString(),
      'youtube_key': getYouTubeTrailerKey(tvdbData['name'], _getYear(tvdbData)),
      'priority_score': 0.0,
    };
  }

  static String _getDirector(Map<String, dynamic> tvdbData) {
    if (tvdbData['characters'] != null) {
      for (var character in tvdbData['characters']) {
        if (character['type'] == 'Director') {
          return character['personName'] ?? 'Unknown';
        }
      }
    }
    return 'Unknown';
  }

  static String _getCast(Map<String, dynamic> tvdbData) {
    List<String> cast = [];
    if (tvdbData['characters'] != null) {
      for (var character in tvdbData['characters']) {
        if (character['type'] == 'Actor' && cast.length < 5) {
          cast.add(character['personName'] ?? 'Unknown');
        }
      }
    }
    return cast.join(', ').isEmpty ? 'Unknown' : cast.join(', ');
  }

  static String _getYear(Map<String, dynamic> tvdbData) {
    String? date = tvdbData['first_air_date'] ?? tvdbData['release_date'];
    if (date != null && date.length >= 4) {
      return date.substring(0, 4);
    }
    return 'Unknown';
  }

  static double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is num) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }
}