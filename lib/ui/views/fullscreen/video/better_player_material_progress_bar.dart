/// https://github.com/jhomlala/betterplayer/blob/master/lib/src/controls/better_player_material_progress_bar.dart

import 'dart:async';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class BetterPlayerMaterialVideoProgressBar extends StatefulWidget {
  BetterPlayerMaterialVideoProgressBar(
    this.betterPlayerController, {
    BetterPlayerProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.onTapDown,
    Key? key,
  })  : colors = colors ?? BetterPlayerProgressColors(),
        super(key: key);

  final BetterPlayerController? betterPlayerController;
  final BetterPlayerProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;
  final Function()? onTapDown;

  @override
  State createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState
    extends State<BetterPlayerMaterialVideoProgressBar> {
  _VideoProgressBarState() {
    listener = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    };
  }

  late VoidCallback listener;
  bool _controllerWasPlaying = false;

  BetterPlayerController? get betterPlayerController =>
      widget.betterPlayerController;

  bool shouldPlayAfterDragEnd = false;
  Duration? lastSeek;
  Timer? _updateBlockTimer;

  @override
  void initState() {
    super.initState();
    betterPlayerController!.videoPlayerController!.addListener(listener);
  }

  @override
  void deactivate() {
    betterPlayerController!.videoPlayerController!.removeListener(listener);
    _cancelUpdateBlockTimer();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final bool enableProgressBarDrag = betterPlayerController!
        .betterPlayerConfiguration.controlsConfiguration.enableProgressBarDrag;

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (!betterPlayerController!.videoPlayerController!.value.initialized ||
            !enableProgressBarDrag) {
          return;
        }

        _controllerWasPlaying =
            betterPlayerController!.videoPlayerController!.value.isPlaying;
        if (_controllerWasPlaying) {
          betterPlayerController!.videoPlayerController!.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart!();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!betterPlayerController!.videoPlayerController!.value.initialized ||
            !enableProgressBarDrag) {
          return;
        }

        seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate!();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (!enableProgressBarDrag) {
          return;
        }

        if (_controllerWasPlaying) {
          betterPlayerController?.play();
          shouldPlayAfterDragEnd = true;
        }
        _setupUpdateBlockTimer();

        if (widget.onDragEnd != null) {
          widget.onDragEnd!();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (!betterPlayerController!.videoPlayerController!.value.initialized ||
            !enableProgressBarDrag) {
          return;
        }
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

  VideoPlayerValue _getValue() {
    if (lastSeek != null) {
      return betterPlayerController!.videoPlayerController!.value
          .copyWith(position: lastSeek);
    } else {
      return betterPlayerController!.videoPlayerController!.value;
    }
  }

  void seekToRelativePosition(Offset globalPosition) async {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject != null) {
      final box = renderObject as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      if (relative > 0) {
        final Duration position =
            betterPlayerController!.videoPlayerController!.value.duration! *
                relative;
        lastSeek = position;
        await betterPlayerController!.seekTo(position);
        onFinishedLastSeek();
        if (relative >= 1) {
          lastSeek =
              betterPlayerController!.videoPlayerController!.value.duration;
          await betterPlayerController!.seekTo(
              betterPlayerController!.videoPlayerController!.value.duration!);
          onFinishedLastSeek();
        }
      }
    }
  }

  void onFinishedLastSeek() {
    if (shouldPlayAfterDragEnd) {
      shouldPlayAfterDragEnd = false;
      betterPlayerController?.play();
    }
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.value, this.colors);

  VideoPlayerValue value;
  BetterPlayerProgressColors colors;

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
    if (!value.initialized) {
      return;
    }
    double playedPartPercent =
        value.position.inMilliseconds / value.duration!.inMilliseconds;
    if (playedPartPercent.isNaN) {
      playedPartPercent = 0;
    }
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (final range in value.buffered) {
      double start = range.startFraction(value.duration!) * size.width;
      if (start.isNaN) {
        start = 0;
      }
      double end = range.endFraction(value.duration!) * size.width;
      if (end.isNaN) {
        end = 0;
      }
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
    }
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
