import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String? description;

  const VideoPlayerScreen({
    required this.videoId,
    required this.title,
    this.description,
    Key? key,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final _firestoreService = FirestoreService();
  late YoutubePlayerController _controller;

  bool completed = false;
  bool allowed = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    checkViews();
  }

  Future<void> checkViews() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final views =
        await _firestoreService.getRemainingViewsForVideo(uid, widget.videoId);

    setState(() {
      loading = false;
      allowed = views > 0;
    });

    if (allowed) {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          controlsVisibleAtStart: true,
        ),
      )..addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (!_controller.value.isReady || completed) return;

    final position = _controller.value.position.inSeconds;
    final duration = _controller.metadata.duration.inSeconds;

    if (duration > 0) {
      final progress = position / duration;

      if (progress >= 0.9) {
        _handleVideoCounted();
      }
    }

    if (_controller.value.playerState == PlayerState.ended) {
      _handleVideoCounted();
    }
  }

  Future<void> _handleVideoCounted() async {
    if (!completed) {
      completed = true;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _firestoreService
          .decrementRemainingViewsForVideo(uid, widget.videoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم خصم مشاهدة")),
        );
      }
    }
  }

  @override
  void dispose() {
    if (allowed) _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return loading
        ? const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          )
        : !allowed
            ? const Scaffold(
                body: Center(
                  child: Text(
                    "⚠️ انتهت عدد المشاهدات المسموح بها لهذا الفيديو.",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            : YoutubePlayerBuilder(
                onEnterFullScreen: () {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ]);
                },
                onExitFullScreen: () {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.portraitDown,
                  ]);
                },
                player: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.red,
                  onReady: () {
                    _controller.addListener(_videoListener);
                  },
                ),
                builder: (context, player) {
                  return Scaffold(
                    appBar: isLandscape ? null : AppBar(
                      title: Text(widget.title),
                      elevation: 0,
                    ),
                    body: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // 🎬 فيديو داخل كارت احترافي
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: player,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 📝 الوصف داخل كارت
                          if (!isLandscape &&
                              widget.description != null &&
                              widget.description!.isNotEmpty)
                            Expanded(
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Description",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Linkify(
                                          onOpen: (link) async {
                                            final url = Uri.parse(link.url);
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(
                                                url,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            }
                                          },
                                          text: widget.description!,
                                          style:
                                              const TextStyle(fontSize: 14),
                                          linkStyle: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
  }
}
