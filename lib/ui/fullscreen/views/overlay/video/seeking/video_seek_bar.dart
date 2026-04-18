import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/seeking/video_seek_model.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/video/seeking/video_seek_preview.dart';
import 'package:provider/provider.dart';

class VideoSeekBar extends StatelessWidget {
  final VideoController videoController;
  final double height;
  final VideoProgressBarColors colors;

  const VideoSeekBar(
    this.videoController, {
    required this.height,
    required this.colors,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) => _onSeek(context, details.localPosition),
      onHorizontalDragEnd: (details) {
        _onSeek(context, details.localPosition);
        _onSeekEnd(context);
      },
      onTapDown: (details) => _onSeek(context, details.localPosition),
      onTapUp: (details) => _onSeek(context, details.localPosition),
      onTap: () => _onSeekEnd(context),
      child: _buildSeekBar(context),
    );
  }

  Widget _buildSeekBar(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        VideoSeekPreview(),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height,
            width: MediaQuery.of(context).size.width,
            color: Colors.transparent,
            child: StreamProvider.value(
              value: StreamGroup.merge([videoController.player.stream.buffer, videoController.player.stream.position]),
              initialData: Duration(),
              child: Consumer<Duration>(
                builder: (BuildContext context, Duration value, Widget? child) {
                  return CustomPaint(
                    painter: _ProgressBarPainter(
                      _getValue(context),
                      colors,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onSeek(BuildContext context, Offset localPosition) {
    final duration = _getDurationFromPosition(context, localPosition);
    if (duration == null) {
      _onSeekEnd(context);
    } else {
      context.read<VideoSeekModel>().onSeek(duration, localPosition);
    }
  }

  void _onSeekEnd(BuildContext context) {
    context.read<VideoSeekModel>().onSeekEnd();
  }

  Duration? _getDurationFromPosition(BuildContext context, Offset localPosition) {
    final width = context.size?.width;
    if (width == null) return null;
    final double relative = localPosition.dx / width;
    if (relative < 0 || relative > 1) return null;

    return videoController.player.state.duration * relative;
  }

  VideoProgress _getValue(BuildContext context) {
    return VideoProgress(
      duration: videoController.player.state.duration,
      position: videoController.player.state.position,
      buffered: videoController.player.state.buffer,
      dragPosition: context.select<VideoSeekModel, double?>((model) => model.ongoingDragPosition?.dx),
    );
  }
}

class VideoProgress {
  final Duration duration;
  final Duration position;
  final Duration buffered;
  final double? dragPosition;

  VideoProgress({
    required this.duration,
    required this.position,
    required this.buffered,
    required this.dragPosition,
  });

  double getPlayedPartEnd(Size size) {
    if (duration.inMilliseconds == 0) return 0;
    double progress = position.inMilliseconds / duration.inMilliseconds;
    return progress > 1 ? size.width : progress * size.width;
  }

  double getBufferedPartEnd(Size size) {
    if (duration.inMilliseconds == 0) return 0;
    double progress = buffered.inMilliseconds / duration.inMilliseconds;
    return progress > 1 ? size.width : progress * size.width;
  }
}

class VideoProgressBarColors {
  VideoProgressBarColors({
    required this.playedColor,
    required Color bufferedColor,
    required Color handleColor,
    required Color backgroundColor,
  }) : bufferedPaint = Paint()..color = bufferedColor,
       handlePaint = Paint()..color = handleColor,
       backgroundPaint = Paint()..color = backgroundColor;

  final Color playedColor;
  final Paint bufferedPaint;
  final Paint handlePaint;
  final Paint backgroundPaint;
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.videoProgress, this.colors);

  final VideoProgress videoProgress;
  final VideoProgressBarColors colors;
  static const double _barHeight = 4.0;
  static const double _handleRadius = 7.0;
  static const double _dragHandleRadius = 9.0;

  @override
  bool shouldRepaint(CustomPainter painter) => true;

  void _paintRRect(Canvas canvas, double start, double end, double y, double h, Paint paint) {
    if (end <= start) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(start, y, end - start, h),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height / 2 - _barHeight / 2;
    final double playedEnd = videoProgress.getPlayedPartEnd(size);
    final double bufferedEnd = videoProgress.getBufferedPartEnd(size);
    final bool isDragging = videoProgress.dragPosition != null;
    final double handleX = videoProgress.dragPosition ?? playedEnd;
    final Offset handleCenter = Offset(handleX, y + _barHeight / 2);

    _paintRRect(canvas, 0, size.width, y, _barHeight, colors.backgroundPaint);
    _paintRRect(canvas, 0, bufferedEnd, y, _barHeight, colors.bufferedPaint);

    if (playedEnd > 0) {
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            colors.playedColor.withValues(alpha: 0.45),
            colors.playedColor,
          ],
        ).createShader(Rect.fromLTWH(0, y, playedEnd, _barHeight));
      _paintRRect(canvas, 0, playedEnd, y, _barHeight, gradientPaint);
    }

    if (isDragging) {
      canvas.drawCircle(
        handleCenter,
        _dragHandleRadius * 2.5,
        Paint()
          ..color = colors.playedColor.withValues(alpha: 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        handleCenter,
        _dragHandleRadius + 4,
        Paint()
          ..color = colors.playedColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(handleCenter, _dragHandleRadius, colors.handlePaint);
    } else {
      canvas.drawCircle(handleCenter, _handleRadius, colors.handlePaint);
    }
  }
}
