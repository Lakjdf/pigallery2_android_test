
import 'package:flutter/gestures.dart';

/// Custom [ScaleGestureRecognizer] which does not pick up gestures with only 1 pointer.
/// See also https://github.com/flutter/flutter/issues/13102
class TwoFingerScaleGestureRecognizer extends ScaleGestureRecognizer {
  TwoFingerScaleGestureRecognizer({super.debugOwner});

  bool _gestureAccepted = false;

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);

    if (pointerCount > 1 && !_gestureAccepted) {
      resolve(GestureDisposition.accepted);
      _gestureAccepted = true;
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (!_gestureAccepted) {
      resolve(GestureDisposition.rejected);
    }
    super.didStopTrackingLastPointer(pointer);
    _gestureAccepted = false;
  }
}
