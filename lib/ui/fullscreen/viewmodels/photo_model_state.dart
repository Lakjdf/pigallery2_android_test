import 'dart:typed_data';

import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';

class PhotoModelState {
  Uint8List? video;
  final String url;

  PhotoModelState(this.url);

  /// For playing the video part of the motion photo.
  /// Returns null if it is not a motion video, or has not been downloaded yet.
  AppVideoController? videoController;

  /// Whether the photo is a motion photo.
  /// Always returns false until it has been downloaded.
  bool get isMotionPhoto => video != null;
}
