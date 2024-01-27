import 'package:flutter/material.dart';

/// Ensures that a [ChangeNotifier] does not try to notify a listener after being disposed.
class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
