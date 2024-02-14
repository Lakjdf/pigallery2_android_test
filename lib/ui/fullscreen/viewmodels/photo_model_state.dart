import 'dart:typed_data';

import 'package:better_player/better_player.dart';

class PhotoModelState {
  Uint8List? video;
  final String url;

  PhotoModelState(this.url);

  /// For playing the video part of the motion photo.
  /// Returns null if it is not a motion video, or has not been downloaded yet.
  BetterPlayerController? betterPlayerController;

  /// Whether the [betterPlayerController] has been initialized.
  bool get isVideoInitialized => betterPlayerController?.isVideoInitialized() ?? false;

  /// Whether the photo is a motion photo.
  /// Always returns false until it has been downloaded.
  bool get isMotionPhoto => video != null;
}
