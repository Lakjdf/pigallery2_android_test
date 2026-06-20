import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/app_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/mediakit/media_kit_video_controller.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/mediakit/media_kit_video_player.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/playback/video_player_factory.dart';

/// [VideoPlayerFactory] backed by `media_kit` / `media_kit_video`.
///
/// This is the only place in the app that references those packages.
class MediaKitVideoPlayerFactory implements VideoPlayerFactory {
  final Logger _logger = Logger("MediaKitVideoPlayer");

  /// Whether to use the Android `mediacodec_embed` video output (hardware
  /// surface embedding). When false, media_kit's default render configuration
  /// is used — texture rendering, the same internal view path as `video_player`.
  final bool useEmbeddedCodec;

  /// Whether to disable libmpv read-ahead caching for low streaming latency
  /// (applies to streaming controllers only).
  final bool lowLatencyCache;

  MediaKitVideoPlayerFactory({this.useEmbeddedCodec = true, this.lowLatencyCache = true});

  @override
  void ensureInitialized() {
    MediaKit.ensureInitialized();
  }

  @override
  AppVideoController createStreamingController() {
    final player = Player(
      configuration: PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024,
        logLevel: kDebugMode ? MPVLogLevel.debug : MPVLogLevel.warn,
      ),
    );
    if (lowLatencyCache) {
      // https://github.com/media-kit/media-kit/issues/776#issuecomment-2072158673
      // Disable read-ahead caching to keep streaming latency/memory low.
      final platform = player.platform as dynamic;
      platform.setProperty('cache', 'no'); // --cache=<yes|no|auto>
      platform.setProperty('cache-secs', '0'); // --cache-secs=<seconds>
      platform.setProperty('demuxer-seekable-cache', 'no'); // --demuxer-seekable-cache=<yes|no|auto>
      platform.setProperty('demuxer-max-back-bytes', '0'); // --demuxer-max-back-bytes=<bytesize>
      platform.setProperty('demuxer-donate-buffer', 'no'); // --demuxer-donate-buffer=<yes|no>
    }
    player.setPlaylistMode(PlaylistMode.loop);
    player.stream.log.listen((event) => _logger.fine(event.toString()));

    final controller = VideoController(player, configuration: _configuration());
    return MediaKitVideoController(controller, MediaKitVideoPlayer(player));
  }

  @override
  AppVideoController createMotionPhotoController() {
    final player = Player();
    // By default media_kit/mpv rotates the video. Disable it; the UI applies its
    // own rotation compensation. Must be applied before opening, so it gates open.
    final ready = (player.platform as NativePlayer).setProperty("video-rotate", "no");
    player.setPlaylistMode(PlaylistMode.loop);

    final controller = VideoController(player, configuration: _configuration());
    return MediaKitVideoController(
      controller,
      MediaKitVideoPlayer(player, ready: ready),
      showDefaultControls: true,
    );
  }

  /// Platform-specific render configuration (formerly VideoControllerConfigFactory).
  VideoControllerConfiguration _configuration() {
    if (!useEmbeddedCodec) {
      // media_kit defaults: libmpv texture rendering.
      return const VideoControllerConfiguration();
    }
    if (Platform.isAndroid) {
      return const VideoControllerConfiguration(
        vo: "mediacodec_embed",
        hwdec: "mediacodec",
        enableHardwareAcceleration: true,
        androidAttachSurfaceAfterVideoParameters: false,
      );
    } else {
      return const VideoControllerConfiguration(
        vo: "libmpv",
        hwdec: "mediacodec",
        enableHardwareAcceleration: false,
        androidAttachSurfaceAfterVideoParameters: false,
      );
    }
  }
}
