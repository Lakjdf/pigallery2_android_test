import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoSeekBar extends StatefulWidget {
  const VideoSeekBar(
    this.videoController, {
    required this.colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.onTapDown,
    super.key,
  });

  final VideoController videoController;
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
    return Center(
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width,
        color: Colors.transparent,
        child: CustomPaint(
          painter: _ProgressBarPainter(
            _getValue(),
            widget.colors,
          ),
        ),
      ),
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
    videoController.player.seek(position)
        .then((_) => _onSeekComplete(position));
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

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const height = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(size.width, size.height / 2 + height),
        ),
        const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    double playedPartPercent = value.position.inMilliseconds / value.duration.inMilliseconds;
    if (playedPartPercent.isNaN) {
      playedPartPercent = 0;
    }
    final double playedPart = playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    double start = 0;
    double bufferedPartPercent = value.buffered.inMilliseconds / value.duration.inMilliseconds;
    if (bufferedPartPercent.isNaN) {
      bufferedPartPercent = 0;
    }
    double end = bufferedPartPercent * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(start, size.height / 2),
          Offset(end, size.height / 2 + height),
        ),
        const Radius.circular(4.0),
      ),
      colors.bufferedPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(playedPart, size.height / 2 + height),
        ),
        const Radius.circular(4.0),
      ),
      colors.playedPaint,
    );
    canvas.drawCircle(
      Offset(playedPart, size.height / 2 + height / 2),
      height * 3,
      colors.handlePaint,
    );
  }
}
