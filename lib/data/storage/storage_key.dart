import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';

enum StorageKey<T> {
  serverUrls<List<String>>([]),
  selectedServer<int>(0),
  useMaterial3<bool>(true),
  showTopPicks<bool>(true),
  topPicksDaysLength<int>(1),
  sortOption<SortOption>(SortOption.name),
  sortAscending<bool>(true),
  showDirectoryItemCount<bool>(false),
  gridRoundedCorners<int>(6),
  gridSpacing<int>(6),
  gridAspectRatio<double>(1),
  gridCrossAxisCountPortrait<int>(3),
  gridCrossAxisCountLandscape<int>(5),
  allowBadCertificates<bool>(false),
  showVideoSeekPreview<bool>(false),
  apiBasePath<String>("/pgapi"),
  apiThumbnailPath<String>("/320"),
  mediaBackgroundMode<MediaBackgroundMode>(MediaBackgroundMode.ambient),
  mediaBackgroundBlur<int>(45),
  apiVideoPath<String>("");

  String get key => name;
  final T defaultValue;

  const StorageKey(this.defaultValue);
}
