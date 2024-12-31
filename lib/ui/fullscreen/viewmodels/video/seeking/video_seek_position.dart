import 'dart:ui';

/// Represents the positions while dragging the seek bar.
class VideoSeekPosition {
  final Duration videoPosition;
  final Offset widgetPosition;

  VideoSeekPosition(this.videoPosition, this.widgetPosition);
}
