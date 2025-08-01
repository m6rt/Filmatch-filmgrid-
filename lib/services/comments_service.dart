import 'database_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'profile_service.dart';

class CommentsService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Map<String, dynamic>>> getComments(int movieId) async {
    try {
      final comments = await _databaseService.getComments(movieId);
      return comments.map((comment) {
        return {
          'id': comment['id'],
          'username': comment['username'],
          'rating': comment['rating'],
          'comment': comment['comment'],
          'isSpoiler': comment['isSpoiler'] == 1,
          'language': comment['language'] ?? 'TR',
          'date': _formatDate(comment['createdAt']),
          'createdAt': comment['createdAt'],
          'likesCount': 0, // Bu aşağıda güncellenecek
          'isLiked': false, // Bu aşağıda güncellenecek
        };
      }).toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  // Yorumları beğeni bilgileriyle birlikte getir
  Future<List<Map<String, dynamic>>> getCommentsWithLikes(
    int movieId,
    String currentUsername,
  ) async {
    try {
      final comments = await _databaseService.getComments(movieId);

      final enrichedComments = await Future.wait(
        comments.map((comment) async {
          final commentId = comment['id'] as int;
          final likesCount = await _databaseService.getCommentLikesCount(
            commentId,
          );
          final isLiked = await _databaseService.isCommentLiked(
            commentId,
            currentUsername,
          );

          return {
            'id': comment['id'],
            'username': comment['username'],
            'rating': comment['rating'],
            'comment': comment['comment'],
            'isSpoiler': comment['isSpoiler'] == 1,
            'language': comment['language'] ?? 'TR',
            'date': _formatDate(comment['createdAt']),
            'createdAt': comment['createdAt'],
            'likesCount': likesCount,
            'isLiked': isLiked,
          };
        }).toList(),
      );

      return enrichedComments;
    } catch (e) {
      print('Error getting comments with likes: $e');
      return [];
    }
  }

  // Yorumu beğen
  Future<bool> likeComment(
    int commentId,
    String currentUsername,
    String commentOwnerUsername,
  ) async {
    try {
      final success = await _databaseService.likeComment(
        commentId,
        currentUsername,
      );

      if (success && currentUsername != commentOwnerUsername) {
        // Bildirim gönder
        await _databaseService.addNotification(
          toUsername: commentOwnerUsername,
          fromUsername: currentUsername,
          type: 'comment_like',
          title: 'Yorumunuz beğenildi',
          message: '$currentUsername yorumunuzu beğendi',
          data: commentId.toString(),
        );
      }

      return success;
    } catch (e) {
      print('Error liking comment: $e');
      return false;
    }
  }

  // Yorumu beğenmeyi kaldır
  Future<bool> unlikeComment(int commentId, String currentUsername) async {
    try {
      return await _databaseService.unlikeComment(commentId, currentUsername);
    } catch (e) {
      print('Error unliking comment: $e');
      return false;
    }
  }

  // Kullanıcının mevcut yorumunu getir
  Future<Map<String, dynamic>?> getUserComment(
    int movieId,
    String username,
  ) async {
    try {
      final comment = await _databaseService.getUserComment(movieId, username);
      if (comment == null) return null;

      return {
        'id': comment['id'],
        'username': comment['username'],
        'rating': comment['rating'],
        'comment': comment['comment'],
        'isSpoiler': comment['isSpoiler'] == 1,
        'language': comment['language'] ?? 'TR',
        'date': _formatDate(comment['createdAt']),
        'createdAt': comment['createdAt'],
      };
    } catch (e) {
      print('Error getting user comment: $e');
      return null;
    }
  }

  // Kullanıcının daha önce yorum yapıp yapmadığını kontrol et
  Future<bool> hasUserCommented(int movieId, String username) async {
    try {
      return await _databaseService.hasUserCommented(movieId, username);
    } catch (e) {
      print('Error checking if user commented: $e');
      return false;
    }
  }

  // Yorum ekle
  Future<bool> addComment({
    required int movieId,
    required String username,
    required int rating,
    required String comment,
    required bool isSpoiler,
    required String language,
  }) async {
    try {
      await _databaseService.addComment(
        movieId: movieId,
        username: username,
        rating: rating,
        comment: comment,
        isSpoiler: isSpoiler,
        language: language,
      );

      // Takipçilere bildirim gönder
      try {
        // Circular import'u önlemek için dinamik import
        final profileService = ProfileService();
        final movieTitle = await _getMovieTitle(movieId);
        await profileService.sendCommentNotificationToFollowers(
          username,
          movieId,
          movieTitle ?? 'Bilinmeyen Film',
        );
      } catch (e) {
        print('Error sending follower notifications: $e');
        // Bildirim hatası ana işlemi etkilemesin
      }

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      // Hata mesajını üst katmana ilet
      rethrow;
    }
  }

  // Film başlığını getir (JSON'dan)
  Future<String?> _getMovieTitle(int movieId) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/movie_database.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      final movieJson = jsonList.firstWhere(
        (json) => json['id'] == movieId,
        orElse: () => null,
      );

      return movieJson?['title'];
    } catch (e) {
      print('Error getting movie title: $e');
      return null;
    }
  }

  // Yorumu güncelle
  Future<bool> updateComment({
    required int movieId,
    required String username,
    required int rating,
    required String comment,
    required bool isSpoiler,
    required String language,
  }) async {
    try {
      final result = await _databaseService.updateComment(
        movieId: movieId,
        username: username,
        rating: rating,
        comment: comment,
        isSpoiler: isSpoiler,
        language: language,
      );
      return result > 0;
    } catch (e) {
      print('Error updating comment: $e');
      return false;
    }
  }

  // Kullanıcının yorumunu sil
  Future<bool> deleteUserComment(int movieId, String username) async {
    try {
      final result = await _databaseService.deleteUserComment(
        movieId,
        username,
      );
      return result > 0;
    } catch (e) {
      print('Error deleting user comment: $e');
      return false;
    }
  }

  // Belirli bir kullanıcının tüm yorumlarını getir
  Future<List<Map<String, dynamic>>> getUserComments(String username) async {
    try {
      final comments = await _databaseService.getUserComments(username);
      return comments.map((comment) {
        return {
          'id': comment['id'],
          'movieId': comment['movieId'],
          'username': comment['username'],
          'rating': comment['rating'],
          'comment': comment['comment'],
          'isSpoiler': comment['isSpoiler'] == 1,
          'language': comment['language'] ?? 'TR',
          'date': _formatDate(comment['createdAt']),
          'createdAt': comment['createdAt'],
          'likesCount': 0, // Bu aşağıda güncellenecek
          'isLiked': false, // Bu sadece viewing user için geçerli
        };
      }).toList();
    } catch (e) {
      print('Error getting user comments: $e');
      return [];
    }
  }

  // Belirli bir kullanıcının yorumlarını beğeni bilgileriyle birlikte getir
  Future<List<Map<String, dynamic>>> getUserCommentsWithLikes(
    String username,
    String? viewingUsername,
  ) async {
    try {
      final comments = await _databaseService.getUserComments(username);

      final enrichedComments = await Future.wait(
        comments.map((comment) async {
          final commentId = comment['id'] as int;
          final likesCount = await _databaseService.getCommentLikesCount(
            commentId,
          );
          final isLiked =
              viewingUsername != null
                  ? await _databaseService.isCommentLiked(
                    commentId,
                    viewingUsername,
                  )
                  : false;

          return {
            'id': comment['id'],
            'movieId': comment['movieId'],
            'username': comment['username'],
            'rating': comment['rating'],
            'comment': comment['comment'],
            'isSpoiler': comment['isSpoiler'] == 1,
            'language': comment['language'] ?? 'TR',
            'date': _formatDate(comment['createdAt']),
            'createdAt': comment['createdAt'],
            'likesCount': likesCount,
            'isLiked': isLiked,
          };
        }).toList(),
      );

      return enrichedComments;
    } catch (e) {
      print('Error getting user comments with likes: $e');
      return [];
    }
  }

  // Debug metodu
  Future<void> debugDatabaseTables() async {
    try {
      await _databaseService.debugDatabaseTables();
    } catch (e) {
      print('CommentsService debug error: $e');
    }
  }

  // Reset metodu
  Future<void> resetDatabase() async {
    try {
      await _databaseService.resetDatabase();
    } catch (e) {
      print('CommentsService reset error: $e');
      rethrow;
    }
  }

  // Film ortalama puanını hesapla
  Future<Map<String, dynamic>> getMovieRatingInfo(int movieId) async {
    try {
      final comments = await _databaseService.getComments(movieId);

      if (comments.isEmpty) {
        return {
          'averageRating': 0.0,
          'commentCount': 0,
          'formattedRating': '0.0',
        };
      }

      double totalRating = 0.0;
      int validComments = 0;

      for (final comment in comments) {
        final rating = comment['rating'];
        if (rating != null && rating is int && rating > 0) {
          totalRating += rating;
          validComments++;
        }
      }

      final averageRating =
          validComments > 0 ? totalRating / validComments : 0.0;

      return {
        'averageRating': averageRating,
        'commentCount': validComments,
        'formattedRating': averageRating.toStringAsFixed(1),
      };
    } catch (e) {
      print('Error calculating movie rating: $e');
      return {
        'averageRating': 0.0,
        'commentCount': 0,
        'formattedRating': '0.0',
      };
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Şimdi';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} dakika önce';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} saat önce';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} hafta önce';
      } else {
        return '${(difference.inDays / 30).floor()} ay önce';
      }
    } catch (e) {
      print('Error formatting date: $e');
      return 'Bilinmeyen tarih';
    }
  }
}
