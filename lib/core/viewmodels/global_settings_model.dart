import 'package:flutter/foundation.dart';
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

  bool get galleryRoundedCorners => _galleryRoundedCorners;

  set galleryRoundedCorners(bool value) {
    if (value != _galleryRoundedCorners) {
      _galleryRoundedCorners = value;
      _storageHelper.storeBool(StorageConstants.galleryRoundedCorners, value);
      notifyListeners();
    }
  }

  bool _useMaterial3;
  bool _appInFullScreen;
  bool _showDirectoryItemCount;
  bool _galleryRoundedCorners;
  final StorageHelper _storageHelper;

  GlobalSettingsModel(this._storageHelper)
      : _appInFullScreen = _storageHelper.getBool(StorageConstants.appInFullScreenKey, false),
        _useMaterial3 = _storageHelper.getBool(StorageConstants.useMaterial3Key, true),
        _showDirectoryItemCount = _storageHelper.getBool(StorageConstants.showDirectoryItemCount, true),
        _galleryRoundedCorners = _storageHelper.getBool(StorageConstants.galleryRoundedCorners, false) {
    if (_appInFullScreen) {
      enableFullScreen();
    }
  }
}
