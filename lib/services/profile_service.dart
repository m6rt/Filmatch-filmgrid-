import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../models/movie.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  User? get currentUser => _auth.currentUser;

  // Kullanıcı profili getir
  Future<UserProfile?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!, user.uid);
      } else {
        // İlk kez giriş yapan kullanıcı için profil oluştur
        final newProfile = UserProfile(
          uid: user.uid,
          username: user.displayName ?? 'User${user.uid.substring(0, 6)}',
          email: user.email ?? '',
          profileImageUrl: user.photoURL,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newProfile.toFirestore());
        return newProfile;
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

  // Favori filmleri getir
  Future<List<Movie>> getFavoriteMovies(List<String> movieIds) async {
    if (movieIds.isEmpty) return [];

    try {
      final List<Movie> favoriteMovies = [];

      // Batch olarak film bilgilerini al (Firestore'da movies collection'ı varsa)
      for (String movieId in movieIds.take(3)) {
        // Sadece ilk 3'ünü al
        try {
          final doc = await _firestore.collection('movies').doc(movieId).get();
          if (doc.exists) {
            favoriteMovies.add(Movie.fromJson(doc.data()!));
          }
        } catch (e) {
          print('Error getting movie $movieId: $e');
        }
      }

      return favoriteMovies;
    } catch (e) {
      print('Error getting favorite movies: $e');
      return [];
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
}
