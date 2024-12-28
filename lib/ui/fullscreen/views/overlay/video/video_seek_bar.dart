import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoSeekBar extends StatefulWidget {
  const VideoSeekBar(
    this.videoController, {
    required this.height,
    required this.colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.onTapDown,
    super.key,
  });

  final VideoController videoController;
  final double height;
  final VideoProgressBarColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;
  final Function()? onTapDown;

  @override
  State createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState extends State<VideoSeekBar> {
  /// Current seek position as displayed in the ui
  Duration? _currentSeek;

  VideoController get videoController => widget.videoController;

  @override
  void deactivate() {
    _currentSeek = null;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => _onDragStart(),
      onHorizontalDragUpdate: (details) => _onDragUpdate(details.globalPosition),
      onHorizontalDragEnd: (_) => _onDragEnd(),
      onTapDown: (details) => _onTapDown(details.globalPosition),
      child: _buildProgressBar(),
    );
  }

  Widget _buildProgressBar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // todo draw thumbnail
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: widget.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.transparent,
            child: CustomPaint(
              painter: _ProgressBarPainter(
                _getValue(),
                widget.colors,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onDragStart() {
    widget.onDragStart?.call();
  }

  void _onDragUpdate(Offset globalPosition) {
    seekToRelativePosition(globalPosition);
    widget.onDragUpdate?.call();
  }

  void _onDragEnd() {
    widget.onDragEnd?.call();
  }

  void _onTapDown(Offset globalPosition) {
    seekToRelativePosition(globalPosition);
    widget.onTapDown?.call();
  }

  void seekToRelativePosition(Offset globalPosition) {
    final renderObject = context.findRenderObject() as RenderBox?;
    if (renderObject == null) return;

    final Offset tapPos = renderObject.globalToLocal(globalPosition);
    final double relative = tapPos.dx / renderObject.size.width;
    if (relative < 0 || relative > 1) return;

    final position = videoController.player.state.duration * relative;

    // only seek if there's no seek pending
    var pendingSeek = _currentSeek;
    _currentSeek = position;
    if (pendingSeek == null) {
      seekToPosition(position);
    }
  }

  void seekToPosition(Duration position) {
    videoController.player.seek(position).then((_) => _onSeekComplete(position));
  }

  void _onSeekComplete(Duration position) {
    Duration? pendingSeek = _currentSeek;

    if (pendingSeek != null && pendingSeek != position) {
      seekToPosition(pendingSeek);
    } else {
      _currentSeek = null;
    }
  }

  VideoProgress _getValue() {
    return VideoProgress(
      duration: videoController.player.state.duration,
      position: _currentSeek ?? videoController.player.state.position,
      buffered: videoController.player.state.buffer,
    );
  }
}

class VideoProgress {
  final Duration duration;
  final Duration position;
  final Duration buffered;

  VideoProgress({
    required this.duration,
    required this.position,
    required this.buffered,
  });
}

class VideoProgressBarColors {
  VideoProgressBarColors({
    required Color playedColor,
    required Color bufferedColor,
    required Color handleColor,
    required Color backgroundColor,
  })  : playedPaint = Paint()..color = playedColor,
        bufferedPaint = Paint()..color = bufferedColor,
        handlePaint = Paint()..color = handleColor,
        backgroundPaint = Paint()..color = backgroundColor;

  final Paint playedPaint;
  final Paint bufferedPaint;
  final Paint handlePaint;
  final Paint backgroundPaint;
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.value, this.colors);

  VideoProgress value;
  VideoProgressBarColors colors;
  final double height = 2;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  double _getPlayedPartEnd(Size size) {
    if (value.duration.inMilliseconds == 0) return 0;
    double progress = value.position.inMilliseconds / value.duration.inMilliseconds;
    return progress > 1 ? size.width : progress * size.width;
  }

  double _getBufferedPartEnd(Size size) {
    if (value.duration.inMilliseconds == 0) return 0;
    double progress = value.buffered.inMilliseconds / value.duration.inMilliseconds;
    return progress > 1 ? size.width : progress * size.width;
  }

  void _paintBar(Canvas canvas, double width, Paint paint, double yPos) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0, yPos),
          Offset(width, yPos + height),
        ),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2 - height / 2;

    double playedPartEnd = _getPlayedPartEnd(size);
    double bufferedPartEnd = _getBufferedPartEnd(size);

    _paintBar(canvas, size.width, colors.backgroundPaint, centerY);
    _paintBar(canvas, bufferedPartEnd, colors.bufferedPaint, centerY);
    _paintBar(canvas, playedPartEnd, colors.playedPaint, centerY);
    canvas.drawCircle(
      Offset(playedPartEnd, centerY + height / 2),
      height * 3,
      colors.handlePaint,
    );
  }
}
