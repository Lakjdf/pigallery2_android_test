import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoSeekBar extends StatefulWidget {
  VideoSeekBar(
    this.videoController, {
    VideoProgressBarColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.onTapDown,
    super.key,
  }) : colors = colors ?? VideoProgressBarColors();

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
  bool _controllerWasPlaying = false;

  VideoController get videoController => widget.videoController;

  bool shouldPlayAfterDragEnd = false;
  Duration? lastSeek;
  Timer? _updateBlockTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void deactivate() {
    _cancelUpdateBlockTimer();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        _controllerWasPlaying = videoController.player.state.playing;
        if (_controllerWasPlaying) {
          videoController.player.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart!();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        seekToRelativePosition(details.globalPosition); // wait for previous seek to finish; either skip or queue

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate!();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying) {
          videoController.player.play();
          shouldPlayAfterDragEnd = true;
        }
        _setupUpdateBlockTimer();

        if (widget.onDragEnd != null) {
          widget.onDragEnd!();
        }
      },
      onTapDown: (TapDownDetails details) {
        seekToRelativePosition(details.globalPosition);
        _setupUpdateBlockTimer();
        if (widget.onTapDown != null) {
          widget.onTapDown!();
        }
      },
      child: Center(
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
      ),
    );
  }

  void _setupUpdateBlockTimer() {
    _updateBlockTimer = Timer(const Duration(milliseconds: 1000), () {
      lastSeek = null;
      _cancelUpdateBlockTimer();
    });
  }

  void _cancelUpdateBlockTimer() {
    _updateBlockTimer?.cancel();
    _updateBlockTimer = null;
  }

  VideoProgress _getValue() {
    return VideoProgress(duration: videoController.player.state.duration, position: lastSeek ?? videoController.player.state.position, buffered: videoController.player.state.buffer);
  }

  void seekToRelativePosition(Offset globalPosition) async {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject != null) {
      final box = renderObject as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      if (relative > 0) {
        final Duration position = videoController.player.state.duration * relative;
        lastSeek = position;
        await videoController.player.seek(position);
        onFinishedLastSeek();
        if (relative >= 1) {
          lastSeek = videoController.player.state.duration;
          await videoController.player.seek(videoController.player.state.duration);
          onFinishedLastSeek();
        }
      }
    }
  }

  void onFinishedLastSeek() {
    if (shouldPlayAfterDragEnd) {
      shouldPlayAfterDragEnd = false;
      videoController.player.play();
    }
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
    Color playedColor = const Color.fromRGBO(255, 0, 0, 0.7),
    Color bufferedColor = const Color.fromRGBO(30, 30, 200, 0.2),
    Color handleColor = const Color.fromRGBO(200, 200, 200, 1.0),
    Color backgroundColor = const Color.fromRGBO(200, 200, 200, 0.5),
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
