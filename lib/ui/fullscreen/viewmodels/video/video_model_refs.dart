import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_model_controller_state.dart';

/// Keeps track of how many widgets are referencing a video item.
/// Required to stop playback of videos when they are not visible anymore.
class VideoModelRefs {
  late final VideoModelControllerState _state;

  VideoModelRefs(VideoModelControllerState state) : _state = state;

  /// Maps [models.Media.id]s to how many Widgets referencing their video are currently mounted.
  final Map<int, int> _refs = {};

  /// Decrease the [_refs] counter by 1 for the given id.
  /// Pauses the playback if no other widget references the id.
  void unregisterMountedWidget(int id) {
    int? currentRefs = _refs[id];
    if (currentRefs != null) {
      if (currentRefs <= 1) {
        _refs.remove(id);
        _state.getController(id)?.controller.player.pause();
      } else {
        _refs[id] = currentRefs - 1;
      }
    }
  }

  /// Increase the [_refs] counter by 1 for the given id.
  /// Starts/Resumes playback if this is the first widget registered.
  void registerMountedWidget(int id) {
    _refs.update(id, (value) => value += 1, ifAbsent: () => 1);
    final controller = _state.getController(id);
    if (controller != null) {
      controller.player.play();
    }
  }
}