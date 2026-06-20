import 'package:flutter/widgets.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_player.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/videoplayer/vp_video_player.dart';
import 'package:video_player/video_player.dart';

/// `video_player` backed [AppVideoController].
///
/// Unlike `media_kit`'s `Video`, the [VideoPlayer] widget simply fills its
/// parent, so the requested [BoxFit]/aspect-ratio is reproduced here by sizing
/// the view ourselves. The underlying `Texture` can be referenced by multiple
/// widgets at once (e.g. the main view plus the blurred background).
class VpVideoController implements AppVideoController {
  final VpVideoPlayer _player;

  VpVideoController(this._player);

  @override
  AppVideoPlayer get player => _player;

  @override
  Future<void> get waitUntilFirstFrameRendered => _player.ready;

  @override
  bool get isInitialized => _player.controller?.value.isInitialized ?? false;

  @override
  Future<void> setSize({int? width, int? height}) async {
    // video_player sizes the surface from the decoded video; nothing to do.
  }

  @override
  double? get nativeAspectRatio => _player.aspectRatio;

  @override
  Widget buildView({
    BoxFit fit = BoxFit.contain,
    double? aspectRatio,
    double? width,
    double? height,
    Alignment alignment = Alignment.center,
    Key? key,
  }) {
    final controller = _player.controller;
    if (controller == null || !controller.value.isInitialized) {
      return SizedBox(key: key, width: width, height: height);
    }
    final ratio = aspectRatio ?? _player.aspectRatio ?? controller.value.aspectRatio;
    return SizedBox(
      key: key,
      width: width,
      height: height,
      child: FittedBox(
        fit: fit,
        alignment: alignment,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: ratio,
          height: 1,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
