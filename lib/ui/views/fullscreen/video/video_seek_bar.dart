import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/views/fullscreen/video/better_player_material_progress_bar.dart';

class VideoSeekBar extends StatefulWidget {
  const VideoSeekBar(
    this.controller, {
    Key? key,
  }) : super(key: key);

  final BetterPlayerController controller;

  @override
  State createState() => _VideoSeekBarState();
}

class _VideoSeekBarState extends State<VideoSeekBar> {
  BetterPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!controller.isVideoInitialized()!) return;
          setState(() {});
        });
      }
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    final List<String> tokens = [];
    if (twoDigitHours != "00") {
      tokens.add(twoDigitHours);
    }
    tokens.add(twoDigitMinutes);
    tokens.add(twoDigitSeconds);

    return tokens.join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
      child: Row(
        children: [
          Text(
            formatDuration(controller.videoPlayerController?.value.position ??
                Duration.zero),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: BetterPlayerMaterialVideoProgressBar(
                controller,
                onDragUpdate: () => setState(() {}),
                colors: BetterPlayerProgressColors(
                  handleColor: Colors.white,
                  playedColor: Colors.white,
                  bufferedColor: Colors.white.withAlpha(75),
                  backgroundColor: Colors.white.withAlpha(40),
                ),
              ),
            ),
          ),
          Text(
            formatDuration(controller.videoPlayerController?.value.duration ??
                Duration.zero),
          ),
        ],
      ),
    );
  }
}
