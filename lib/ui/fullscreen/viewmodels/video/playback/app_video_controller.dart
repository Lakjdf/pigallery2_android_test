import 'package:flutter/widgets.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_player.dart';

/// Package-agnostic render handle for a single video.
///
/// Pairs an [AppVideoPlayer] with the means to render its frames as a widget,
/// without exposing the underlying package's controller or widget types.
abstract interface class AppVideoController {
  /// The playback engine driving this controller.
  AppVideoPlayer get player;

  /// Completes once the first frame is ready to be displayed.
  Future<void> get waitUntilFirstFrameRendered;

  /// Whether the controller is ready to render frames.
  bool get isInitialized;

  /// Hint the render surface size. Required for some backends to update the
  /// displayed dimensions; safe to ignore for others.
  Future<void> setSize({int? width, int? height});

  /// Aspect ratio of the rendered surface, or null if not yet known.
  /// Used to compute zoom-to-fill scaling.
  double? get nativeAspectRatio;

  /// Builds the widget that renders this video's frames.
  Widget buildView({
    BoxFit fit = BoxFit.contain,
    double? aspectRatio,
    double? width,
    double? height,
    Alignment alignment = Alignment.center,
    Key? key,
  });
}
