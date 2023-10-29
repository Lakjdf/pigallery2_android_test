import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';

class GlobalSettingsModel extends ChangeNotifier {
  /// Whether to use the dynamic colors retrieved from the Android system.
  /// See https://m3.material.io/styles/color/dynamic-color/user-generated-color.
  bool get useMaterial3 => _useMaterial3;

  /// Toggles the value of [useMaterial3].
  void toggleTheme() {
    _useMaterial3 = !_useMaterial3;
    _storageHelper.storeBool(StorageConstants.useMaterial3Key, _useMaterial3);
    notifyListeners();
  }

  set useMaterial3(bool value) {
    if (value != _useMaterial3) {
      _useMaterial3 = value;
      _storageHelper.storeBool(StorageConstants.useMaterial3Key, value);
      notifyListeners();
    }
  }

  bool get showTopPicks => _showTopPicks;

  set showTopPicks(bool value) {
    if (value != _showTopPicks) {
      _showTopPicks = value;
      _storageHelper.storeBool(StorageConstants.showTopPicksKey, value);
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

  void storeTopPicksDaysLength() => _storageHelper.storeInt(StorageConstants.topPicksDaysLengthKey, _topPicksDaysLength);

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
    _storageHelper.storeBool(StorageConstants.appInFullScreenKey, _appInFullScreen);
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
      _storageHelper.storeBool(StorageConstants.showDirectoryItemCount, value);
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

  void storeGridRoundedCorners() => _storageHelper.storeInt(StorageConstants.gridRoundedCorners, _gridRoundedCorners);

  double get gridAspectRatio => _gridAspectRatio;

  set gridAspectRatio(double value) {
    if (value != _gridAspectRatio) {
      _gridAspectRatio = value;
      notifyListeners();
    }
  }

  void storeGridAspectRatio() => _storageHelper.storeDouble(StorageConstants.gridAspectRatio, _gridAspectRatio);

  int get gridSpacing => _gridSpacing;

  set gridSpacing(int value) {
    if (value != _gridSpacing) {
      _gridSpacing = value;
      notifyListeners();
    }
  }

  void storeGridSpacing() => _storageHelper.storeInt(StorageConstants.gridSpacing, _gridSpacing);

  int getGridCrossAxisCount(Orientation orientation) {
    switch(orientation) {
      case Orientation.portrait: return _gridCrossAxisCountPortrait;
      case Orientation.landscape: return _gridCrossAxisCountLandscape;
    }
  }

  void storeGridCrossAxisCount(Orientation orientation, int value) {
    if (value < 0 || value > 10) return;
    switch(orientation) {
      case Orientation.portrait: {
        if (value != _gridCrossAxisCountPortrait) {
          _gridCrossAxisCountPortrait = value;
          _storageHelper.storeInt(StorageConstants.gridCrossAxisCountPortrait, value);
          notifyListeners();
        }
        break;
      }
      case Orientation.landscape: {
        if (value != _gridCrossAxisCountLandscape) {
          _gridCrossAxisCountLandscape = value;
          _storageHelper.storeInt(StorageConstants.gridCrossAxisCountLandscape, value);
          notifyListeners();
        }
        break;
      }
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
  final StorageHelper _storageHelper;

  GlobalSettingsModel(this._storageHelper)
      : _appInFullScreen = _storageHelper.getBool(StorageConstants.appInFullScreenKey, false),
        _useMaterial3 = _storageHelper.getBool(StorageConstants.useMaterial3Key, true),
        _showTopPicks = _storageHelper.getBool(StorageConstants.showTopPicksKey, true),
        _topPicksDaysLength = _storageHelper.getInt(StorageConstants.topPicksDaysLengthKey, 1),
        _showDirectoryItemCount = _storageHelper.getBool(StorageConstants.showDirectoryItemCount, false),
        _gridRoundedCorners = _storageHelper.getInt(StorageConstants.gridRoundedCorners, 6),
        _gridAspectRatio = _storageHelper.getDouble(StorageConstants.gridAspectRatio, 1),
        _gridSpacing = _storageHelper.getInt(StorageConstants.gridSpacing, 6),
        _gridCrossAxisCountPortrait = _storageHelper.getInt(StorageConstants.gridCrossAxisCountPortrait, 3),
        _gridCrossAxisCountLandscape = _storageHelper.getInt(StorageConstants.gridCrossAxisCountLandscape, 5) {
    if (_appInFullScreen) {
      enableFullScreen();
    }
  }
}
