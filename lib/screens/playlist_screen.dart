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

class _MyVideosPageState extends State<MyVideosPage>
    with SingleTickerProviderStateMixin {
  Map<String, String> subjectsWithPlaylists = {};
  bool isLoading = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    setState(() => isLoading = true);

    subjectsWithPlaylists = await FirestoreService().getSubjectsWithPlaylists();

    if (subjectsWithPlaylists.length > 1) {
      _tabController = TabController(
        length: subjectsWithPlaylists.keys.length,
        vsync: this,
      );
    }

    setState(() => isLoading = false);
  }

  Future<List<Map<String, dynamic>>> fetchVideos(String playlistId) async {
    final url = Uri.parse(
      "https://www.googleapis.com/youtube/v3/playlistItems"
      "?part=snippet&maxResults=20&playlistId=$playlistId&key=$YouTubeApiKey",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data == null || data['items'] == null) return [];

      List items = data['items'];
      return items.map<Map<String, dynamic>>((item) {
        final snippet = item['snippet'] ?? {};
        final title = snippet['title'] ?? "";

        if (title.toLowerCase().contains("private") ||
            title.toLowerCase().contains("deleted")) {
          return {};
        }

        return {
          "title": title,
          "thumbnail": snippet['thumbnails']?['high']?['url'] ?? "",
          "videoId": snippet['resourceId']?['videoId'] ?? "",
        };
      }).where((v) => v.isNotEmpty).toList();
    } else {
      throw Exception("فشل تحميل الفيديوهات: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (subjectsWithPlaylists.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("⚠️ لا توجد مواد متاحة لهذا الطالب")),
      );
    }

    final subjects = subjectsWithPlaylists.keys.toList();

    // ✅ لو مادة واحدة بس
    if (subjects.length == 1) {
      final subject = subjects.first;
      final playlistId = subjectsWithPlaylists[subject]!;
      return Scaffold(
        body: buildPlaylist(playlistId),
      );
    }

    // ✅ لو مواد متعددة
    return DefaultTabController(
      length: subjects.length,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 12),
              // Tabs في الأعلى من غير padding
              Container(
                child: TabBar(
                  labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  indicatorWeight: 3,
                  labelPadding: const EdgeInsets.symmetric(
                      horizontal: 16), // تخلي spacing بسيط بين التابات
                  tabs: subjects.map((s) => Tab(text: s)).toList(),
                ),
              ),
          
              // محتوى التابات
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: subjects.map((subject) {
                    final playlistId = subjectsWithPlaylists[subject]!;
                    return buildPlaylist(playlistId);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPlaylist(String playlistId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchVideos(playlistId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("❌ خطأ: ${snapshot.error}"));
        }

        final videos = snapshot.data ?? [];
        if (videos.isEmpty) {
          return const Center(child: Text("📭 لا توجد فيديوهات حالياً"));
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
                    builder: (_) => VideoPlayerScreen(
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
                elevation: 2,
                child: Container(
                  decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.blue.shade100,
          Colors.white,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              video["thumbnail"],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}
