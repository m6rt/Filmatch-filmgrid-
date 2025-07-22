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
          'date': _formatDate(comment['createdAt']),
          'createdAt': comment['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  Future<bool> addComment({
    required int movieId,
    required String username,
    required int rating,
    required String comment,
    required bool isSpoiler,
  }) async {
    try {
      await _databaseService.addComment(
        movieId: movieId,
        username: username,
        rating: rating,
        comment: comment,
        isSpoiler: isSpoiler,
      );
      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  String _formatDate(String isoDate) {
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
  }
}