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
          disableDragSeek: false,
        ),
      )..addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (_controller.value.playerState == PlayerState.ended) {
      _handleVideoEnd();
    }
  }

  Future<void> _handleVideoEnd() async {
    if (!completed) {
      completed = true;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _firestoreService
          .decrementRemainingViewsForVideo(uid, widget.videoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم خصم مشاهدة عند انتهاء الفيديو ✅"),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (allowed) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : !allowed
                ? const Center(
                    child: Text(
                      "⚠️ انتهت عدد المشاهدات المسموح بها لهذا الفيديو.",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                : Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: YoutubePlayer(
                          controller: _controller,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: Colors.red,
                        ),
                      ),
                      if (widget.description != null &&
                          widget.description!.isNotEmpty)
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Linkify(
                              onOpen: (link) async {
                                final url = Uri.parse(link.url);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              text: widget.description!,
                              style: const TextStyle(fontSize: 14),
                              linkStyle: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
  