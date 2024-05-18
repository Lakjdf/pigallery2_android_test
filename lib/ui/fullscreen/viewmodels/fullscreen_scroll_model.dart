import 'dart:async';

/// Provides the current index of the fullscreen PageView.
class FullscreenScrollModel {
  final StreamController<int> _indexStreamController = StreamController.broadcast();

  set currentIndex(int currentIndex) => _indexStreamController.add(currentIndex);

  Stream<int> getCurrentIndex() {
    return _indexStreamController.stream;
  }
}
