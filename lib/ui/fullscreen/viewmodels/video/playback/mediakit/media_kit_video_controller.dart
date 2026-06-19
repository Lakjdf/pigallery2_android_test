import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_player.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/mediakit/media_kit_video_player.dart';

/// `media_kit_video` backed [AppVideoController].
class MediaKitVideoController implements AppVideoController {
  final VideoController _controller;
  final MediaKitVideoPlayer _player;

  /// Motion photos keep the default adaptive controls; streaming video renders
  /// without any built-in controls (the app draws its own overlay).
  final bool _showDefaultControls;

  MediaKitVideoController(this._controller, this._player, {bool showDefaultControls = false})
      : _showDefaultControls = showDefaultControls;

  @override
  AppVideoPlayer get player => _player;

  @override
  Future<void> get waitUntilFirstFrameRendered => _controller.waitUntilFirstFrameRendered;

  @override
  bool get isInitialized => _controller.player.platform?.videoControllerCompleter.isCompleted ?? false;

  @override
  Future<void> setSize({int? width, int? height}) => _controller.setSize(width: width, height: height);

  @override
  double? get nativeAspectRatio {
    final rect = _controller.rect.value;
    if (rect == null || rect.height == 0) return null;
    return rect.width / rect.height;
  }

  @override
  Widget buildView({
    BoxFit fit = BoxFit.contain,
    double? aspectRatio,
    double? width,
    double? height,
    Alignment alignment = Alignment.center,
    Key? key,
  }) {
    return Video(
      key: key,
      controller: _controller,
      fit: fit,
      aspectRatio: aspectRatio,
      controls: _showDefaultControls ? AdaptiveVideoControls : NoVideoControls,
      width: width,
      height: height,
      alignment: alignment,
      pauseUponEnteringBackgroundMode: true,
      resumeUponEnteringForegroundMode: true,
    );
  }
}
