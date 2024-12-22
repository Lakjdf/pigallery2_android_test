import 'dart:io';

import 'package:media_kit_video/media_kit_video.dart';

/// Creates [VideoControllerConfiguration] based on the platform.
class VideoControllerConfigFactory {
  static VideoControllerConfiguration createConfiguration() {
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
