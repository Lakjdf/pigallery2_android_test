import 'package:flutter/rendering.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

/// Tracks the scroll position and direction of the active gallery so the
/// app bar can hide its background and actions while the user scrolls down,
/// and reveal them again when they start scrolling up.
class AppBarScrollModel extends SafeChangeNotifier {
  static const double _topThreshold = 8.0;

  double _offset = 0.0;
  bool _hidden = false;

  double get offset => _offset;

  /// Whether the bar background and actions should currently be revealed.
  bool get showActions => !_hidden;

  /// Called when a different scroll source becomes active (tab switch, route
  /// pop). Adopts the new offset and always reveals the bar so the user sees
  /// it after navigation, regardless of which direction they last scrolled in
  /// the previous view.
  void attach(double offset) {
    bool changed = false;
    if (_offset != offset) {
      _offset = offset;
      changed = true;
    }
    if (_hidden) {
      _hidden = false;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void update({required double offset, required ScrollDirection direction}) {
    bool changed = false;
    if (_offset != offset) {
      _offset = offset;
      changed = true;
    }
    if (offset <= _topThreshold) {
      if (_hidden) {
        _hidden = false;
        changed = true;
      }
    } else if (direction == ScrollDirection.reverse && !_hidden) {
      _hidden = true;
      changed = true;
    } else if (direction == ScrollDirection.forward && _hidden) {
      _hidden = false;
      changed = true;
    }
    if (changed) notifyListeners();
  }
}
