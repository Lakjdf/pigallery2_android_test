import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/views/fullscreen/video/better_player_material_progress_bar.dart';

class VideoSeekBar extends StatefulWidget {
  const VideoSeekBar({
    Key? key,
    required this.controller,
    required this.opacity,
  }) : super(key: key);

  final BetterPlayerController controller;
  final double opacity;

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
    Color onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              formatDuration(controller.videoPlayerController?.value.position ?? Duration.zero),
              style: TextStyle(color: onSurfaceVariant.withOpacity(widget.opacity)),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: BetterPlayerMaterialVideoProgressBar(
                controller,
                onDragUpdate: () => setState(() {}),
                colors: BetterPlayerProgressColors(
                  handleColor: onSurfaceVariant.withOpacity(widget.opacity),
                  playedColor: onSurfaceVariant.withOpacity(widget.opacity),
                  bufferedColor: onSurfaceVariant.withOpacity(.5 * widget.opacity),
                  backgroundColor: onSurfaceVariant.withOpacity(.2 * widget.opacity),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              formatDuration(controller.videoPlayerController?.value.duration ?? Duration.zero),
              style: TextStyle(color: onSurfaceVariant.withOpacity(widget.opacity)),
            ),
          ),
        ],
      ),
    );
  }
}
