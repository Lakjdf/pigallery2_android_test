import 'dart:collection';

import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/sprite_thumbnail_data.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

/// Model for previews while seeking in a video.
class VideoSeekPreviewModel extends SafeChangeNotifier {
  final MediaRepository _mediaRepository;
  bool _enabled;
  SplayTreeMap<Duration, SpriteRegion>? _previews;
  Media _currentItem;

  SpriteRegion? _currentPreview;

  /// The current [SpriteRegion] to be displayed.
  SpriteRegion? get currentPreview => _currentPreview;

  /// Whether previews are available to be displayed.
  bool get isAvailable => _currentPreview != null;

  VideoSeekPreviewModel(FullscreenModel fullscreenModel, this._mediaRepository, GlobalSettingsModel settingsModel)
      : _currentItem = fullscreenModel.currentItem,
        _enabled = settingsModel.showVideoSeekPreview {
    fullscreenModel.addListener(() {
      if (_currentItem != fullscreenModel.currentItem) {
        _currentItem = fullscreenModel.currentItem;
        _onCurrentItemChanged();
      }
    });
    settingsModel.addListener(() {
      if (_enabled != settingsModel.showVideoSeekPreview) {
        _enabled = settingsModel.showVideoSeekPreview;
        _onCurrentItemChanged();
      }
    });
    _onCurrentItemChanged();
  }

  /// Load sprites of thumbnails once the displayed item changes.
  void _onCurrentItemChanged() {
    _currentPreview = null;
    _previews = null;
    if (!_enabled || !_currentItem.isVideo) {
      return;
    }
    _mediaRepository.getSpriteThumbnails(_currentItem).then((val) {
      _previews = val;
      _currentPreview = val?.values.first;
      notifyListeners();
    });
  }

  /// Update the [currentPreview] based on the [position] of the user input.
  void updateSeekPosition(Duration position) {
    final previews = _previews;
    if (previews == null) return;
    _currentPreview = previews[previews.lastKeyBefore(position)];
    notifyListeners();
  }
}
