import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUi {
  static var platform = MethodChannel("com.lakjdf.pigallery_android/statusBar");

  static void hideSystemBars() {
    if (!Platform.isAndroid) return;
    platform.invokeMethod("hideSystemBars");
  }

  static void showSystemBars() {
    if (!Platform.isAndroid) return;
    platform.invokeMethod("showSystemBars");
  }

  static void setDefaultSystemBarColors(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
        statusBarColor: Colors.black.withAlpha(1),
      ),
    );
  }

  static void setFullscreenSystemBarColors(BuildContext context) {
    // should be default for Android 15+
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black.withAlpha(1),
        statusBarColor: Colors.black.withAlpha(1),
      ),
    );
  }

  static EdgeInsets getPadding() {
    final view = PlatformDispatcher.instance.views.first;
    final dpr = view.devicePixelRatio;

    return EdgeInsets.fromLTRB(
      view.viewPadding.left / dpr,
      view.viewPadding.top / dpr,
      view.viewPadding.right / dpr,
      view.viewPadding.bottom / dpr,
    );
  }
}
