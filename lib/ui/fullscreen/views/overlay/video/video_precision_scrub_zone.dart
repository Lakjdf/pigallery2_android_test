import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';

class VideoPrecisionScrubZone extends StatefulWidget {
  final VideoControllerItem controllerItem;

  const VideoPrecisionScrubZone({super.key, required this.controllerItem});

  @override
  State<VideoPrecisionScrubZone> createState() => _VideoPrecisionScrubZoneState();
}

class _VideoPrecisionScrubZoneState extends State<VideoPrecisionScrubZone> {
  static const double _height = 72;
  static const Duration _precisionWindow = Duration(seconds: 10);

  double? _dragStartX;
  Duration? _dragStartPosition;
  bool _wasPlaying = false;
  String? _scrubLabel;

  VideoControllerItem get _item => widget.controllerItem;

  void _onDragStart(DragStartDetails details) {
    _dragStartX = details.localPosition.dx;
    _dragStartPosition = _item.player.position;
    _wasPlaying = _item.player.isPlaying;
    if (_wasPlaying) _item.player.pause();
    setState(() => _scrubLabel = '0.00 s');
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final startX = _dragStartX;
    final startPos = _dragStartPosition;
    if (startX == null || startPos == null) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final deltaX = details.localPosition.dx - startX;
    final seekDelta = _precisionWindow * (deltaX / screenWidth);
    final newPosition = startPos + seekDelta;
    final duration = _item.player.duration;
    final clamped = newPosition < Duration.zero
        ? Duration.zero
        : newPosition > duration
            ? duration
            : newPosition;
    _item.player.seek(clamped);

    final ms = seekDelta.inMilliseconds;
    final sign = ms >= 0 ? '+' : '−';
    final absMs = ms.abs();
    setState(() => _scrubLabel = '$sign${(absMs / 1000.0).toStringAsFixed(2)} s');
  }

  void _reset() {
    if (_wasPlaying) _item.player.play();
    _dragStartX = null;
    _dragStartPosition = null;
    _wasPlaying = false;
    setState(() => _scrubLabel = null);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: (_) => _reset(),
      onHorizontalDragCancel: _reset,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: AnimatedOpacity(
          opacity: _scrubLabel != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: Center(
            child: Text(
              _scrubLabel ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
