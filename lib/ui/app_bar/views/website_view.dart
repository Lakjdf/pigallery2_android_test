import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:provider/provider.dart';

class WebsiteView extends StatefulWidget {
  final String serverUrl;

  const WebsiteView(this.serverUrl, {super.key});

  @override
  State<WebsiteView> createState() => _WebsiteViewState();
}

class _WebsiteViewState extends State<WebsiteView> {
  late InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    NavigatorState navigator = Navigator.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) return;
        if (await _controller?.canGoBack() != true) {
          return navigator.pop();
        } else {
          await _controller?.goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: InAppWebView(
          onWebViewCreated: (controller) => _controller = controller,
          initialUrlRequest: URLRequest(url: WebUri("${widget.serverUrl}/admin")),
          initialSettings: InAppWebViewSettings(
            forceDark: ForceDark.ON,
            algorithmicDarkeningAllowed: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            transparentBackground: true,
          ),
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
