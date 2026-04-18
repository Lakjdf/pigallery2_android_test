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

  Widget _buildProgressBar(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Colors.white;
    return VideoSeekBar(
      controller,
      key: ObjectKey(controller),
      height: height,
      colors: VideoProgressBarColors(
        handleColor: primary.withValues(alpha: opacity),
        playedColor: primary.withValues(alpha: opacity),
        bufferedColor: onSurface.withValues(alpha: 0.3 * opacity),
        backgroundColor: onSurface.withValues(alpha: 0.12 * opacity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            VideoProgressBarText(
              initialValue: controller.player.state.position,
              stream: controller.player.stream.position,
              opacity: opacity,
              color: Colors.white,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildProgressBar(context),
              ),
            ),
            VideoProgressBarText(
              initialValue: controller.player.state.duration,
              stream: controller.player.stream.duration,
              opacity: opacity,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
