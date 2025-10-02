import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class YoutubeService {
  Future<List<Map<String, String>>> fetchPlaylistVideos(String playlistId) async {
  final url =
      'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=20&playlistId=$playlistId&key=$YouTubeApiKey';

  final response = await http.get(Uri.parse(url));
print("🌐 طلب API: $url");
print("📥 استجابة API: ${response.statusCode} ${response.body}");

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final videos = data['items'] as List;

    return videos.map<Map<String, String>>((video) {
      final snippet = video['snippet'];
      return {
        'videoId': snippet['resourceId']['videoId'] as String,
        'title': snippet['title'] as String,
        'thumbnail': snippet['thumbnails']['high']['url'] as String,
      };
    }).toList();
  } else {
  throw Exception("خطأ من API: ${response.statusCode} ${response.body}");
}

}

}
