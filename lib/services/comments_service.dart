import 'database_service.dart';

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
        };
      }).toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
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
      return true;
    } catch (e) {
      print('Error adding comment: $e');
      // Hata mesajını üst katmana ilet
      rethrow;
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
