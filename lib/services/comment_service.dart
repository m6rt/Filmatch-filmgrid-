import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment.dart';

class CommentService {
  static const String _baseUrl =
      'YOUR_API_BASE_URL'; // API URL'inizi buraya ekleyin

  Future<List<Comment>> getMovieComments(String movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movies/$movieId/comments'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching movie comments: $e');
      return [];
    }
  }

  Future<List<Comment>> getUserComments(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/comments'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching user comments: $e');
      return [];
    }
  }

  Future<Comment?> addComment({
    required String movieId,
    required String movieTitle,
    required String moviePosterUrl,
    required String content,
    double? rating,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'movieId': movieId,
          'movieTitle': movieTitle,
          'moviePosterUrl': moviePosterUrl,
          'content': content,
          'rating': rating,
        }),
      );

      if (response.statusCode == 201) {
        return Comment.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  Future<bool> updateComment(
    String commentId,
    String content,
    double? rating,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': content, 'rating': rating}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating comment: $e');
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }
}
