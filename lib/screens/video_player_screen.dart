import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  VideoPlayerScreen({required this.videoId, required this.title});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  final _firestoreService = FirestoreService();
  bool completed = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(autoPlay: true),
    )..addListener(checkProgress);
  }

  void checkProgress() async {
    if (_controller.value.isReady && !_controller.value.isFullScreen) {
      final duration = _controller.metadata.duration.inSeconds;
      final position = _controller.value.position.inSeconds;

      if (duration > 0 && position >= duration - 2 && !completed) {
        completed = true; // عشان مايتخصمش مرتين
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await _firestoreService.decrementRemainingViews(uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تم خصم مشاهدة بعد إنهاء الفيديو")),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(checkProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      ),
    );
  }
}
