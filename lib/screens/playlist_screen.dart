import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learning_app/constants.dart';
import 'package:learning_app/screens/video_player_screen.dart';

class MyVideosPage extends StatefulWidget {
  const MyVideosPage({super.key});

  @override
  State<MyVideosPage> createState() => _MyVideosPageState();
}

class _MyVideosPageState extends State<MyVideosPage> {
  Future<List<Map<String, dynamic>>> fetchVideos() async {
    const String playlistId =
        "PLx2MaK-MX7kwCVbd6yrYQt1p-Ze6pKt3j"; // 📌 ضيفي الـ Playlist ID هنا

    final url = Uri.parse(
      "https://www.googleapis.com/youtube/v3/playlistItems"
      "?part=snippet&maxResults=10&playlistId=$playlistId&key=$YouTubeApiKey",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data == null || data['items'] == null) {
        throw Exception("لم يتم العثور على فيديوهات 😢");
      }

      List items = data['items'];

      // تأكد إن كل فيديو فيه بيانات سليمة
      return items.map<Map<String, dynamic>>((item) {
        final snippet = item['snippet'] ?? {};
        return {
          "title": snippet['title'] ?? "بدون عنوان",
          "thumbnail": snippet['thumbnails']?['default']?['url'] ?? "",
          "videoId": snippet['resourceId']?['videoId'] ?? "",
        };
      }).toList();
    } else {
      throw Exception("فشل تحميل الفيديوهات: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Videos")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchVideos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("❌ خطأ: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لا توجد فيديوهات 🎞️"));
          }

          final videos = snapshot.data!;

          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return ListTile(
                leading: video["thumbnail"].isNotEmpty
                    ? Image.network(video["thumbnail"])
                    : const Icon(Icons.video_library),
                title: Text(video["title"]),
                onTap: () {
                    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VideoPlayerScreen(
        videoId: video["videoId"],
        title: video["title"],
      ),
    ),
  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
