import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
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

  /// Enter full screen. Disregards [appInFullScreen].
  void enableFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Leave full screen. Disregards [appInFullScreen].
  void disableFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
  }

  /// Whether the application is in full screen mode.
  /// Fullscreen mode will always be entered when entering [FullScreenView] disregarding this setting.
  bool get appInFullScreen => _appInFullScreen;

  /// Toggle value of [appInFullScreen].
  void toggleAppInFullScreen() {
    _appInFullScreen = !_appInFullScreen;
    _storage.set(StorageKey.appInFullScreen, _appInFullScreen);
    notifyListeners();
    if (_appInFullScreen) {
      enableFullScreen();
    } else {
      disableFullScreen();
    }
  }

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

  bool _useMaterial3;
  bool _showTopPicks;
  int _topPicksDaysLength;
  bool _appInFullScreen;
  bool _showDirectoryItemCount;
  int _gridRoundedCorners;
  double _gridAspectRatio;
  int _gridSpacing;
  int _gridCrossAxisCountPortrait;
  int _gridCrossAxisCountLandscape;
  bool _showVideoSeekPreview;
  final SharedPrefsStorage _storage;

  GlobalSettingsModel(this._storage)
      : _appInFullScreen = _storage.get(StorageKey.appInFullScreen),
        _useMaterial3 = _storage.get(StorageKey.useMaterial3),
        _showTopPicks = _storage.get(StorageKey.showTopPicks),
        _topPicksDaysLength = _storage.get(StorageKey.topPicksDaysLength),
        _showDirectoryItemCount = _storage.get(StorageKey.showDirectoryItemCount),
        _gridRoundedCorners = _storage.get(StorageKey.gridRoundedCorners),
        _gridAspectRatio = _storage.get(StorageKey.gridAspectRatio),
        _gridSpacing = _storage.get(StorageKey.gridSpacing),
        _gridCrossAxisCountPortrait = _storage.get(StorageKey.gridCrossAxisCountPortrait),
        _gridCrossAxisCountLandscape = _storage.get(StorageKey.gridCrossAxisCountLandscape),
        _showVideoSeekPreview = _storage.get(StorageKey.showVideoSeekPreview) {
    if (_appInFullScreen) {
      enableFullScreen();
    }
  }
}
