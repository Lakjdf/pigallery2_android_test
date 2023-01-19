import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebsiteView extends StatefulWidget {
  final String serverUrl;

  const WebsiteView(this.serverUrl, {Key? key}) : super(key: key);

  @override
  State<WebsiteView> createState() => _WebsiteViewState();
}

class _WebsiteViewState extends State<WebsiteView> {
  late InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller?.canGoBack() != true) {
          return true;
        } else {
          await _controller?.goBack();
          return false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: InAppWebView(
          onWebViewCreated: (controller) => _controller = controller,
          initialUrlRequest: URLRequest(url: WebUri("${widget.serverUrl}/admin")),
        ),
      ),
    );
  }
}
