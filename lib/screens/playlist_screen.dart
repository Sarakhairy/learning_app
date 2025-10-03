import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learning_app/constants.dart';
import 'package:learning_app/screens/video_player_screen.dart';
import 'package:learning_app/services/firestore_service.dart';

class MyVideosPage extends StatefulWidget {
  const MyVideosPage({super.key});

  @override
  State<MyVideosPage> createState() => _MyVideosPageState();
}

class _MyVideosPageState extends State<MyVideosPage> {
  String? level;
  String? playlistId;
  bool isLoading = true;

  Future<List<Map<String, dynamic>>> fetchVideos() async {
    if (playlistId == null) return [];

    final url = Uri.parse(
      "https://www.googleapis.com/youtube/v3/playlistItems"
      "?part=snippet&maxResults=20&playlistId=$playlistId&key=$YouTubeApiKey",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data == null || data['items'] == null) {
        return [];
      }

      List items = data['items'];

      return items.map<Map<String, dynamic>>((item) {
        final snippet = item['snippet'] ?? {};
        final title = snippet['title'] ?? "";

        // ❌ تجاهل الفيديوهات الخاصة أو المحذوفة
        if (title.toLowerCase().contains("private") ||
            title.toLowerCase().contains("deleted")) {
          return {};
        }

        return {
          "title": title,
          "thumbnail": snippet['thumbnails']?['high']?['url'] ?? "",
          "videoId": snippet['resourceId']?['videoId'] ?? "",
        };
      }).where((video) => video.isNotEmpty).toList();
    } else {
      throw Exception("فشل تحميل الفيديوهات: ${response.statusCode}");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    level = await FirestoreService().getStudentLevel();
    if (level != null) {
      playlistId = await FirestoreService().getPlaylistIdForLevel(level!);
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "📺 دروس الفيديو",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : playlistId == null
              ? const Center(
                  child: Text("⚠️ لم يتم العثور على Playlist لهذا المستوى."),
                )
              : FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchVideos(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text("❌ خطأ: ${snapshot.error}"),
                      );
                    }

                    final videos = snapshot.data ?? [];

                    if (videos.isEmpty) {
                      return const Center(
                        child: Text("📭 لا توجد فيديوهات حالياً"),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return GestureDetector(
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
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // صورة الفيديو
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Image.network(
                                      video["thumbnail"],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // عنوان الفيديو
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    video["title"],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
