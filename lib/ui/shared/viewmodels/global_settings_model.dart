import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

/// Wrapper around [SharedPrefsStorage] to enable Widgets to listen for changes.
class GlobalSettingsModel extends SafeChangeNotifier {
  /// Whether to use the dynamic colors retrieved from the Android system.
  /// See https://m3.material.io/styles/color/dynamic-color/user-generated-color.
  bool get useMaterial3 => _useMaterial3;

  /// Toggles the value of [useMaterial3].
  void toggleTheme() {
    _useMaterial3 = !_useMaterial3;
    _storage.set(StorageKey.useMaterial3, _useMaterial3);
    notifyListeners();
  }

  set useMaterial3(bool value) {
    if (value != _useMaterial3) {
      _useMaterial3 = value;
      _storage.set(StorageKey.useMaterial3, value);
      notifyListeners();
    }
  }

  bool get showTopPicks => _showTopPicks;

  set showTopPicks(bool value) {
    if (value != _showTopPicks) {
      _showTopPicks = value;
      _storage.set(StorageKey.showTopPicks, value);
      notifyListeners();
    }
  }

  int get topPicksDaysLength => _topPicksDaysLength;

  set topPicksDaysLength(int value) {
    if (value != _topPicksDaysLength) {
      _topPicksDaysLength = value;
      notifyListeners();
    }
  }

  void storeTopPicksDaysLength() => _storage.set(StorageKey.topPicksDaysLength, _topPicksDaysLength);

  bool get showDirectoryItemCount => _showDirectoryItemCount;

  set showDirectoryItemCount(bool value) {
    if (value != _showDirectoryItemCount) {
      _showDirectoryItemCount = value;
      _storage.set(StorageKey.showDirectoryItemCount, value);
      notifyListeners();
    }
  }

  int get gridRoundedCorners => _gridRoundedCorners;

  set gridRoundedCorners(int value) {
    if (value != _gridRoundedCorners) {
      _gridRoundedCorners = value;
      notifyListeners();
    }
  }

  void storeGridRoundedCorners() => _storage.set(StorageKey.gridRoundedCorners, _gridRoundedCorners);

  double get gridAspectRatio => _gridAspectRatio;

  set gridAspectRatio(double value) {
    if (value != _gridAspectRatio) {
      _gridAspectRatio = value;
      notifyListeners();
    }
  }

  void storeGridAspectRatio() => _storage.set(StorageKey.gridAspectRatio, _gridAspectRatio);

  int get gridSpacing => _gridSpacing;

  set gridSpacing(int value) {
    if (value != _gridSpacing) {
      _gridSpacing = value;
      notifyListeners();
    }
  }

  void storeGridSpacing() => _storage.set(StorageKey.gridSpacing, _gridSpacing);

  int getGridCrossAxisCount(Orientation orientation) {
    switch (orientation) {
      case Orientation.portrait:
        return _gridCrossAxisCountPortrait;
      case Orientation.landscape:
        return _gridCrossAxisCountLandscape;
    }
  }

  void storeGridCrossAxisCount(Orientation orientation, int value) {
    if (value < 0 || value > 10) return;
    switch (orientation) {
      case Orientation.portrait:
        {
          if (value != _gridCrossAxisCountPortrait) {
            _gridCrossAxisCountPortrait = value;
            _storage.set(StorageKey.gridCrossAxisCountPortrait, value);
            notifyListeners();
          }
          break;
        }
      case Orientation.landscape:
        {
          if (value != _gridCrossAxisCountLandscape) {
            _gridCrossAxisCountLandscape = value;
            _storage.set(StorageKey.gridCrossAxisCountLandscape, value);
            notifyListeners();
          }
          break;
        }
    }
  }

  bool get showVideoSeekPreview => _showVideoSeekPreview;

  set showVideoSeekPreview(bool value) {
    if (value != _showVideoSeekPreview) {
      _showVideoSeekPreview = value;
      _storage.set(StorageKey.showVideoSeekPreview, value);
      notifyListeners();
    }
  }

  String get apiBasePath => _apiBasePath;

  set apiBasePath(String value) {
    if (value != _apiBasePath) {
      _apiBasePath = value;
      _storage.set(StorageKey.apiBasePath, value);
      notifyListeners();
    }
  }

  String get apiThumbnailPath => _apiThumbnailPath;

  set apiThumbnailPath(String value) {
    if (value != _apiThumbnailPath) {
      _apiThumbnailPath = value;
      _storage.set(StorageKey.apiThumbnailPath, value);
      notifyListeners();
    }
  }

  String get apiVideoPath => _apiVideoPath;

  set apiVideoPath(String value) {
    if (value != _apiVideoPath) {
      _apiVideoPath = value;
      _storage.set(StorageKey.apiVideoPath, value);
      notifyListeners();
    }
  }

  int get mediaBackgroundBlur => _mediaBackgroundBlur;

  set mediaBackgroundBlur(int value) {
    if (value != _mediaBackgroundBlur) {
      _mediaBackgroundBlur = value;
      _storage.set(StorageKey.mediaBackgroundBlur, value);
      notifyListeners();
    }
  }

  MediaBackgroundMode get mediaBackgroundMode => _mediaBackgroundMode;

  set mediaBackgroundMode(MediaBackgroundMode option) {
    _mediaBackgroundMode = option;
    _storage.set(StorageKey.mediaBackgroundMode, option);
    notifyListeners();
  }

  bool _useMaterial3;
  bool _showTopPicks;
  int _topPicksDaysLength;
  bool _showDirectoryItemCount;
  int _gridRoundedCorners;
  double _gridAspectRatio;
  int _gridSpacing;
  int _gridCrossAxisCountPortrait;
  int _gridCrossAxisCountLandscape;
  bool _showVideoSeekPreview;
  String _apiBasePath;
  String _apiThumbnailPath;
  String _apiVideoPath;
  int _mediaBackgroundBlur;
  MediaBackgroundMode _mediaBackgroundMode;
  final SharedPrefsStorage _storage;

  GlobalSettingsModel(this._storage)
    : _useMaterial3 = _storage.get(StorageKey.useMaterial3),
      _showTopPicks = _storage.get(StorageKey.showTopPicks),
      _topPicksDaysLength = _storage.get(StorageKey.topPicksDaysLength),
      _showDirectoryItemCount = _storage.get(StorageKey.showDirectoryItemCount),
      _gridRoundedCorners = _storage.get(StorageKey.gridRoundedCorners),
      _gridAspectRatio = _storage.get(StorageKey.gridAspectRatio),
      _gridSpacing = _storage.get(StorageKey.gridSpacing),
      _gridCrossAxisCountPortrait = _storage.get(StorageKey.gridCrossAxisCountPortrait),
      _gridCrossAxisCountLandscape = _storage.get(StorageKey.gridCrossAxisCountLandscape),
      _showVideoSeekPreview = _storage.get(StorageKey.showVideoSeekPreview),
      _apiBasePath = _storage.get(StorageKey.apiBasePath),
      _apiThumbnailPath = _storage.get(StorageKey.apiThumbnailPath),
      _mediaBackgroundBlur = _storage.get(StorageKey.mediaBackgroundBlur),
      _mediaBackgroundMode = _storage.get(StorageKey.mediaBackgroundMode),
      _apiVideoPath = _storage.get(StorageKey.apiVideoPath);
}
