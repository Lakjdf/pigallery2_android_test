import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Holds a [VideoController] alongside its error events.
/// Required since error events are not buffered.
class VideoControllerItem {
  final VideoController controller;
  final List<String> _errorEvents = [];

  VideoControllerItem(this.controller) {
    controller.player.stream.error.listen((value) {
      _errorEvents.add(value);
    });
  }

  Stream<String> errorStream() async* {
    for (String event in _errorEvents) {
      yield event;
    }
    yield* controller.player.stream.error;
  }

  Player get player => controller.player;
}