import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class YouTubeService {
  static String get _apiKey => dotenv.env['YOUTUBE_API_KEY'] ?? ''; // ✅ Güvenli
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  static Future<String?> getMovieTrailer(String movieTitle, String year) async {
    try {
      if (_apiKey.isEmpty) {
        print('⚠️ YouTube API key not found');
        return null;
      }

      final query = '$movieTitle $year trailer';
      final url =
          '$_baseUrl/search?part=snippet&maxResults=1&q=$query&type=video&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data['items'][0]['id']['videoId'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting YouTube trailer: $e');
      return null;
    }
  }
}
