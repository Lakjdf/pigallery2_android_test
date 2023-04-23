import 'package:flutter/foundation.dart';
import 'package:pigallery2_android/core/services/storage_helper.dart';

class ThemingModel extends ChangeNotifier {
  bool _useMaterial3 = true;

  /// Whether to use the dynamic colors retrieved from the Android system.
  /// See https://m3.material.io/styles/color/dynamic-color/user-generated-color.
  bool get useMaterial3 => _useMaterial3;

  /// Toggles the value of [useMaterial3].
  void switchTheme() {
    _useMaterial3 = !_useMaterial3;
    _storageHelper.storeUseMaterial3(_useMaterial3);
    notifyListeners();
  }

  final StorageHelper _storageHelper;

  ThemingModel(this._storageHelper) {
    _storageHelper.getUseMaterial3().then((value) {
      _useMaterial3 = value;
      notifyListeners();
    });
  }
}
