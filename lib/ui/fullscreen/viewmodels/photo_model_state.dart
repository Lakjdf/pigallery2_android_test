import 'dart:typed_data';

import 'package:better_player/better_player.dart';
import 'package:motion_photos/motion_photos.dart';
import 'package:pigallery2_android/util/extensions.dart';

class PhotoModelState {
  MotionPhotos? _photo;
  VideoIndex? _videoIndex;

  PhotoModelState(this.url);

  String url;

  /// For playing the video part of the motion photo.
  /// Returns null if it is not a motion video, or has not been downloaded yet.
  BetterPlayerController? betterPlayerController;

  /// Whether the [betterPlayerController] has been initialized.
  bool get isVideoInitialized => betterPlayerController?.isVideoInitialized() ?? false;

  /// Retrieve the video part of the motion photo.
  /// Returns null if it is not a motion video, or has not been downloaded yet.
  Future<Uint8List?> getMotionVideo() async {
    return _videoIndex?.let((it) => _photo?.getMotionVideo(index: it));
  }

  /// Whether the photo is a motion photo.
  /// Always returns false until it has been downloaded.
  bool get isMotionPhoto => _videoIndex != null;

  /// Load the downloaded file to check whether it is a motion photo.
  Future<void> onDownloadFinished(String path) async {
    _photo = MotionPhotos(path);
    _videoIndex = await _photo!.getMotionVideoIndex();
  }
}
