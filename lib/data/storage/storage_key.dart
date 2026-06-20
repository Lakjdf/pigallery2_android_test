import 'package:pigallery2_android/data/storage/models/server_settings.dart';
import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/domain/models/video_player_backend.dart';

enum StorageKey<T> {
  useMaterial3<bool>(true),
  showTopPicks<bool>(true),
  topPicksDaysLength<int>(1),
  showDirectoryItemCount<bool>(true),
  gridRoundedCorners<int>(0),
  gridSpacing<int>(2),
  gridAspectRatio<double>(1),
  gridCrossAxisCountPortrait<int>(4),
  gridCrossAxisCountLandscape<int>(6),
  allowBadCertificates<bool>(false),
  showVideoSeekPreview<bool>(false),
  videoPlayerBackend<VideoPlayerBackend>(VideoPlayerBackend.mediaKit),
  mediaKitLowLatencyCache<bool>(true),
  mediaBackgroundMode<MediaBackgroundMode>(MediaBackgroundMode.ambient),
  mediaBackgroundBlur<int>(45),
  selectedTab<int>(0),
  serverSettings<ServerSettings>(
    ServerSettings(
      servers: [],
      defaultApiSettings: ApiSettings(thumbnailPath: "/320", videoPath: "", imagePath: ""),
      selectedServer: "",
    ),
  );

  String get key => name;
  final T defaultValue;

  const StorageKey(this.defaultValue);
}
