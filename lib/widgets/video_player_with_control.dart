import 'package:appinio_video_player/appinio_video_player.dart';
import 'package:flutter/material.dart';

class VideoPlayerWithControl extends StatefulWidget {
  const VideoPlayerWithControl({
    super.key,
    required this.url,
  });

  final Uri url;

  @override
  VideoPlayerWithControlState createState() => VideoPlayerWithControlState();
}

class VideoPlayerWithControlState extends State<VideoPlayerWithControl> {
  late VideoPlayerController _videoPlayerController;
  late CustomVideoPlayerController _customVideoPlayerController;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.networkUrl(widget.url)
      ..initialize().then((_) {
        debugPrint('Video initialized');
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
    _customVideoPlayerController = CustomVideoPlayerController(
      context: context,
      videoPlayerController: _videoPlayerController,
      customVideoPlayerSettings: const CustomVideoPlayerSettings(
        showFullscreenButton: true,
        playButton: Padding(
          padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
          child: Icon(Icons.play_circle),
        ),
        pauseButton: Padding(
          padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
          child: Icon(Icons.pause_circle),
        ),
        enterFullscreenButton: Padding(
          padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
          child: Icon(Icons.fullscreen),
        ),
        settingsButton: Padding(
          padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
          child: Icon(Icons.settings),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('Video disposing...');
    _customVideoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _videoPlayerController.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: Stack(
                  children: [
                    CustomVideoPlayer(
                      customVideoPlayerController: _customVideoPlayerController,
                    ),
                  ],
                ),
              )
            : Container(
                color: Colors.black26,
                child: Center(
                  child: IconButton.filled(
                    onPressed: () {
                      debugPrint('Manual Video initializing...');
                      _videoPlayerController.initialize().then((_) {
                        setState(() {});
                      });
                    },
                    icon: const Icon(Icons.replay),
                  ),
                ),
              ),
      ],
    );
  }
}
