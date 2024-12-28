import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/video/video_seek_bar.dart';

class VideoProgressBar extends StatefulWidget {
  const VideoProgressBar({
    super.key,
    required this.controller,
    required this.opacity,
    this.height = 50,
  });

  final VideoController controller;
  final double opacity;
  final double height;

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

  Widget _buildLeftTime(Color color) {
    return Text(
      formatDuration(controller.player.state.position),
      style: TextStyle(color: color.withValues(alpha: widget.opacity)),
    );
  }

  Widget _buildRightTime(Color color) {
    return Text(
      formatDuration(controller.player.state.duration),
      style: TextStyle(color: color.withValues(alpha: widget.opacity)),
    );
  }

  Widget _buildProgressBar(Color color) {
    return VideoSeekBar(
      controller,
      height: widget.height,
      onDragUpdate: () => setState(() {}),
      colors: VideoProgressBarColors(
        handleColor: color.withValues(alpha: widget.opacity),
        playedColor: color.withValues(alpha: widget.opacity),
        bufferedColor: color.withValues(alpha: .5 * widget.opacity),
        backgroundColor: color.withValues(alpha: .2 * widget.opacity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          height: widget.height,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: widget.height,
                child: Align(
                  alignment: Alignment.center,
                  child: _buildLeftTime(onSurfaceVariant),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _buildProgressBar(onSurfaceVariant),
                ),
              ),
              SizedBox(
                height: widget.height,
                child: Align(
                  alignment: Alignment.center,
                  child: _buildRightTime(onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
