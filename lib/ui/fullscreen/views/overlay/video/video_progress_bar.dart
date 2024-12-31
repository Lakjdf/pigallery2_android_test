import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/video/seeking/video_seek_bar.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/video/video_progress_bar_text.dart';

class VideoProgressBar extends StatelessWidget {
  final VideoController controller;
  final double opacity;
  final double height;

  const VideoProgressBar({
    super.key,
    required this.controller,
    required this.opacity,
    this.height = 50,
  });

  Widget _buildProgressBar(Color color) {
    return VideoSeekBar(
      controller,
      key: ObjectKey(controller),
      height: height,
      colors: VideoProgressBarColors(
        handleColor: color.withValues(alpha: opacity),
        playedColor: color.withValues(alpha: opacity),
        bufferedColor: color.withValues(alpha: .5 * opacity),
        backgroundColor: color.withValues(alpha: .2 * opacity),
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
          height: height,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: height,
                child: Align(
                  alignment: Alignment.center,
                  child: VideoProgressBarText(
                    initialValue: controller.player.state.position,
                    stream: controller.player.stream.position,
                    opacity: opacity,
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _buildProgressBar(onSurfaceVariant),
                ),
              ),
              SizedBox(
                height: height,
                child: Align(
                  alignment: Alignment.center,
                  child: VideoProgressBarText(
                    initialValue: controller.player.state.duration,
                    stream: controller.player.stream.duration,
                    opacity: opacity,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
