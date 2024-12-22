import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/video/video_seek_bar.dart';

class VideoProgressBar extends StatefulWidget {
  const VideoProgressBar({
    super.key,
    required this.controller,
    required this.opacity,
  });

  final VideoController controller;
  final double opacity;

  @override
  State createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  VideoController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.player.stream.position.listen((event) {
      if (!mounted) return;
      setState(() {});
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
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              formatDuration(controller.player.state.position),
              style: TextStyle(color: onSurfaceVariant.withValues(alpha: widget.opacity)),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: VideoSeekBar(
                controller,
                onDragUpdate: () => setState(() {}),
                colors: VideoProgressBarColors(
                  handleColor: onSurfaceVariant.withValues(alpha: widget.opacity),
                  playedColor: onSurfaceVariant.withValues(alpha: widget.opacity),
                  bufferedColor: onSurfaceVariant.withValues(alpha: .5 * widget.opacity),
                  backgroundColor: onSurfaceVariant.withValues(alpha: .2 * widget.opacity),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              formatDuration(controller.player.state.duration),
              style: TextStyle(color: onSurfaceVariant.withValues(alpha: widget.opacity)),
            ),
          ),
        ],
      ),
    );
  }
}
