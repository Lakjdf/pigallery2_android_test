import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/web_view_model.dart';
import 'package:pigallery2_android/ui/home/views/error_screen.dart';
import 'package:pigallery2_android/ui/home/views/glass_nav_bar.dart';
import 'package:pigallery2_android/util/strings.dart';
import 'package:provider/provider.dart';

class WebsiteView extends StatelessWidget {
  const WebsiteView({super.key});

  @override
  Widget build(BuildContext context) {
    TabNavigatorModel tabNavigatorModel = context.read<TabNavigatorModel>();
    WebViewModel webViewModel = context.read<WebViewModel>();
    String? serverUrl = context.select<WebViewModel, String?>((it) => it.serverUrl);
    if (serverUrl == null) {
      return ErrorScreen(error: Strings.errorNoServerConfigured);
    }
    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom +
              GlassNavBarTheme.barHeight +
              GlassNavBarTheme.bottomPadding +
              16, // extra padding to clear the nav bar properly
        ),
        child: InAppWebView(
        key: ValueKey(serverUrl),
        onWebViewCreated: (controller) {
          tabNavigatorModel.unregisterWebViewBackHandler();
        },
        gestureRecognizers: {Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer())},
        initialUrlRequest: URLRequest(url: WebUri("$serverUrl/admin")),
        initialSettings: InAppWebViewSettings(
          forceDark: ForceDark.ON,
          algorithmicDarkeningAllowed: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          transparentBackground: true,
        ),
        onUpdateVisitedHistory: (controller, _, _) async {
          bool canGoBack = await controller.canGoBack();
          if (canGoBack) {
            tabNavigatorModel.registerWebViewBackHandler(() {
              controller.goBack();
            });
          } else {
            tabNavigatorModel.unregisterWebViewBackHandler();
          }
          webViewModel.canGoBack = canGoBack;
        },
        onTitleChanged: (controller, title) async {
          context.read<WebViewModel>().title = title ?? "";
        },
        onReceivedServerTrustAuthRequest: (controller, challenge) async {
          if (context.read<SharedPrefsStorage>().get(StorageKey.allowBadCertificates) == true) {
            return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
          } else {
            return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.CANCEL);
          }
        },
      ),
      ),
    );
  }
}
