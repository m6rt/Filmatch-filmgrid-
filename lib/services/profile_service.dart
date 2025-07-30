import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../models/movie.dart';
import '../services/comments_service.dart';
import 'batch_optimized_movie_service.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Service'leri ekleyelim
  final CommentsService _commentsService = CommentsService();
  final BatchOptimizedMovieService _movieService = BatchOptimizedMovieService();

  User? get currentUser => _auth.currentUser;

  // Kullanıcı profili getir
  Future<UserProfile?> getUserProfile([String? username]) async {
    try {
      if (username != null) {
        // Public profile için username ile arama
        final querySnapshot =
            await _firestore
                .collection('users')
                .where('username', isEqualTo: username)
                .limit(1)
                .get();

        if (querySnapshot.docs.isEmpty) {
          return null;
        }

        final userData = querySnapshot.docs.first.data();
        final docId = querySnapshot.docs.first.id;

        return UserProfile.fromFirestore(userData, docId);
      } else {
        // Kendi profili için mevcut kullanıcı
        final user = currentUser;
        if (user == null) return null;

        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          return UserProfile.fromFirestore(doc.data()!, user.uid);
        } else {
          // İlk kez giriş yapan kullanıcı için profil oluştur
          final newProfile = UserProfile(
            uid: user.uid,
            username: user.displayName ?? 'User${user.uid.substring(0, 6)}',
            email: user.email ?? '',
            profileImageUrl: user.photoURL ?? '',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newProfile.toFirestore());
          return newProfile;
        }
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Profil güncelle
  Future<bool> updateProfile(UserProfile profile) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(profile.copyWith(lastUpdated: DateTime.now()).toFirestore());
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Profil fotoğrafı seç ve yükle
  Future<String?> pickAndUploadProfileImage() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      // Fotoğraf seç
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return null;

      // Firebase Storage'a yükle
      final file = File(image.path);
      final storageRef = _storage.ref().child('profile_images/${user.uid}');

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_by': user.uid,
            'uploaded_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Favori film ekle
  Future<bool> addFavoriteMovie(String movieId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'favoriteMovieIds': FieldValue.arrayUnion([movieId]),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('Error adding favorite movie: $e');
      return false;
    }
  }

  // Favori film çıkar
  Future<bool> removeFavoriteMovie(String movieId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'favoriteMovieIds': FieldValue.arrayRemove([movieId]),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('Error removing favorite movie: $e');
      return false;
    }
  }

  // Favori filmleri getir (Local JSON'dan)
  Future<List<Movie>> getFavoriteMovies(List<String> movieIds) async {
    if (movieIds.isEmpty) return [];

    try {
      // Local JSON'dan tüm filmleri yükle
      final String jsonString = await rootBundle.loadString(
        'assets/movies_database.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<Movie> allMovies =
          jsonList.map((json) => Movie.fromJson(json)).toList();

      final List<Movie> favoriteMovies = [];

      // Movie ID'leri int'e çevir ve eşleştir
      for (String movieIdStr in movieIds) {
        try {
          final int movieId = int.parse(movieIdStr);
          final movie = allMovies.firstWhere(
            (m) => m.id == movieId,
            orElse: () => throw Exception('Movie not found'),
          );
          favoriteMovies.add(movie);
        } catch (e) {
          print('Error finding movie $movieIdStr: $e');
        }
      }

      return favoriteMovies;
    } catch (e) {
      print('Error getting favorite movies: $e');
      return [];
    }
  }

  // Watchlist'e film ekle
  Future<bool> addToWatchlist(String movieId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'watchlistMovieIds': FieldValue.arrayUnion([movieId]),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('Error adding to watchlist: $e');
      return false;
    }
  }

  // Watchlist'ten film çıkar
  Future<bool> removeFromWatchlist(String movieId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'watchlistMovieIds': FieldValue.arrayRemove([movieId]),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('Error removing from watchlist: $e');
      return false;
    }
  }

  // Tüm watchlist'i temizle
  Future<bool> clearWatchlist() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'watchlistMovieIds': [],
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('Error clearing watchlist: $e');
      return false;
    }
  }

  // Watchlist filmlerini getir
  Future<List<Movie>> getWatchlistMovies(List<String> movieIds) async {
    if (movieIds.isEmpty) return [];

    try {
      // Local JSON'dan tüm filmleri yükle
      final String jsonString = await rootBundle.loadString(
        'assets/movies_database.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<Movie> allMovies =
          jsonList.map((json) => Movie.fromJson(json)).toList();

      final List<Movie> watchlistMovies = [];

      // Movie ID'leri int'e çevir ve eşleştir
      for (String movieIdStr in movieIds) {
        try {
          final int movieId = int.parse(movieIdStr);
          final movie = allMovies.firstWhere(
            (m) => m.id == movieId,
            orElse: () => throw Exception('Movie not found'),
          );
          watchlistMovies.add(movie);
        } catch (e) {
          print('Error finding movie $movieIdStr: $e');
        }
      }

      return watchlistMovies;
    } catch (e) {
      print('Error getting watchlist movies: $e');
      return [];
    }
  }

  // Filmin favorilerde olup olmadığını kontrol et
  Future<bool> isMovieInFavorites(String movieId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final favoriteIds = List<String>.from(
          doc.data()?['favoriteMovieIds'] ?? [],
        );
        return favoriteIds.contains(movieId);
      }
      return false;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Kullanıcının watchlist'indeki film ID'lerini getir
  Future<List<String>> getWatchlistMovieIds() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final watchlistIds = List<String>.from(
          doc.data()?['watchlistMovieIds'] ?? [],
        );
        return watchlistIds;
      }
      return [];
    } catch (e) {
      print('Error getting watchlist movie IDs: $e');
      return [];
    }
  }

  // Filmin watchlist'te olup olmadığını kontrol et
  Future<bool> isMovieInWatchlist(String movieId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final watchlistIds = List<String>.from(
          doc.data()?['watchlistMovieIds'] ?? [],
        );
        return watchlistIds.contains(movieId);
      }
      return false;
    } catch (e) {
      print('Error checking watchlist status: $e');
      return false;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Profil stream'i (gerçek zamanlı güncellemeler için)
  Stream<UserProfile?> get profileStream {
    final user = currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!, user.uid);
      }
      return null;
    });
  }

  // Diğer kullanıcıların profilini getir
  Future<UserProfile?> getUserProfileByUsername(String username) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final docId = querySnapshot.docs.first.id;
        return UserProfile.fromFirestore(userData, docId);
      }
      return null;
    } catch (e) {
      print('Error getting user profile by username: $e');
      return null;
    }
  }

  // Kullanıcının public yorumlarını getir
  Future<List<Map<String, dynamic>>> getUserPublicComments(
    String username,
  ) async {
    try {
      final comments = await _commentsService.getUserComments(username);

      // Film bilgilerini ekle
      final enrichedComments = await Future.wait(
        comments.map((comment) async {
          try {
            final movieId = comment['movieId'];
            final movie = await _movieService.getMovieById(movieId);
            if (movie != null) {
              comment['movie'] = movie;
            }
          } catch (e) {
            print('Error loading movie for comment: $e');
          }
          return comment;
        }),
      );

      return enrichedComments;
    } catch (e) {
      print('Error getting user public comments: $e');
      return [];
    }
  }

  // Kullanıcının public watchlist'ini getir
  Future<List<Movie>> getUserPublicWatchlist(String username) async {
    try {
      final userProfile = await getUserProfileByUsername(username);
      if (userProfile == null) return [];

      // Privacy kontrolü
      if (!userProfile.isWatchlistPublic) return [];

      // User'ın watchlist'ini al
      final watchlistSnapshot =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (watchlistSnapshot.docs.isEmpty) return [];

      final userData = watchlistSnapshot.docs.first.data();
      final watchlistIds = List<String>.from(
        userData['watchlistMovieIds'] ?? [],
      );

      // Movie detaylarını getir
      final movies = <Movie>[];
      for (final movieId in watchlistIds.take(20)) {
        // Limit 20
        try {
          final movie = await _movieService.getMovieById(int.parse(movieId));
          if (movie != null) {
            movies.add(movie);
          }
        } catch (e) {
          print('Error parsing movie ID $movieId: $e');
        }
      }

      return movies;
    } catch (e) {
      print('Error getting user public watchlist: $e');
      return [];
    }
  }

  // Kullanıcının public favorilerini getir
  Future<List<Movie>> getUserPublicFavorites(String username) async {
    try {
      final userProfile = await getUserProfileByUsername(username);
      if (userProfile == null) return [];

      // Privacy kontrolü
      if (!userProfile.isFavoritesPublic) return [];

      // User'ın favori filmlerini al
      final favoritesSnapshot =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (favoritesSnapshot.docs.isEmpty) return [];

      final userData = favoritesSnapshot.docs.first.data();
      final favoriteIds = List<String>.from(userData['favoriteMovieIds'] ?? []);

      // Movie detaylarını getir
      final movies = <Movie>[];
      for (final movieId in favoriteIds.take(20)) {
        // Limit 20
        try {
          final movie = await _movieService.getMovieById(int.parse(movieId));
          if (movie != null) {
            movies.add(movie);
          }
        } catch (e) {
          print('Error parsing movie ID $movieId: $e');
        }
      }

      return movies;
    } catch (e) {
      print('Error getting user public favorites: $e');
      return [];
    }
  }

  // Tüm kullanıcıları getir
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();

      List<UserProfile> users = [];

      for (var doc in querySnapshot.docs) {
        try {
          final userData = doc.data();
          final docId = doc.id;

          // UserProfile.fromFirestore kullanarak oluştur
          final user = UserProfile.fromFirestore(userData, docId);
          users.add(user);
        } catch (e) {
          print('Kullanıcı verisi parse hatası: $e');
        }
      }

      return users;
    } catch (e) {
      print('Kullanıcılar yüklenirken hata: $e');
      return [];
    }
  }

  // Kullanıcının yorumlarını getir
  Future<List<Map<String, dynamic>>> getUserComments(String username) async {
    try {
      final commentsService = CommentsService();
      return await commentsService.getUserComments(username);
    } catch (e) {
      print('Error getting user comments: $e');
      return [];
    }
  }

  // Film ID'lerini Movie objelerine çevir (JSON dosyasından)
  Future<List<Movie>> getMoviesByIds(List<String> movieIds) async {
    if (movieIds.isEmpty) return [];

    try {
      // Local JSON'dan tüm filmleri yükle
      final String jsonString = await rootBundle.loadString(
        'assets/movies_database.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<Movie> allMovies =
          jsonList.map((json) => Movie.fromJson(json)).toList();

      final List<Movie> requestedMovies = [];

      // Movie ID'leri int'e çevir ve eşleştir
      for (String movieIdStr in movieIds) {
        try {
          final int movieId = int.parse(movieIdStr);
          final movie = allMovies.firstWhere(
            (m) => m.id == movieId,
            orElse: () => throw Exception('Movie not found'),
          );
          requestedMovies.add(movie);
        } catch (e) {
          print('Error finding movie $movieIdStr: $e');
          // Bu filmi atla, diğerlerini yüklemeye devam et
        }
      }

      return requestedMovies;
    } catch (e) {
      print('Error getting movies by ids: $e');
      return [];
    }
  }
}
