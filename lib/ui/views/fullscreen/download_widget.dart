import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pigallery2_android/core/models/media.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class DownloadWidget extends StatefulWidget {
  final Media item;
  final double opacity;

  const DownloadWidget({Key? key, required this.item, required this.opacity}) : super(key: key);

  @override
  State<DownloadWidget> createState() => _DownloadWidgetState();
}

class _DownloadWidgetState extends State<DownloadWidget> {
  int _total = 0, _received = 0;
  bool _downloading = false;
  bool awaitingCancel = false;
  final List<int> _bytes = [];
  late http.StreamedResponse _response;

  void _resetState() {
    setState(() {
      _bytes.clear();
      _total = 0;
      _received = 0;
      _downloading = false;
      awaitingCancel = false;
    });
  }

  Future<void> _showShareDialog(File file) {
    return Share.shareXFiles([XFile(file.path)]).then((value) => _resetState());
  }

  Future<void> _downloadImage(Function(File) action) async {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    String path = model.getMediaApiPath(model.currentState, widget.item);
    String filename = path.split('/').last;
    final file = File('${(await getTemporaryDirectory()).path}/${filename.split('.').first}-${widget.item.id}.${filename.split('.').last}');
    if (file.existsSync()) {
      action(file);
      return;
    }
    _response = await http.Client().send(http.Request('GET', Uri.parse(path))..headers.addAll(model.getHeaders()));
    setState(() {
      _total = _response.contentLength ?? 0;
      _downloading = true;
    });

    late StreamSubscription<List<int>> subscription;
    subscription = _response.stream.listen((value) {
      if (awaitingCancel) {
        subscription.cancel().then((value) => _resetState());
        return;
      }
      if (mounted) {
        setState(() {
          _bytes.addAll(value);
          _received += value.length;
        });
      } else {
        subscription.cancel();
      }
    });
    subscription.onDone(() async {
      await file.writeAsBytes(_bytes);
      action(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: 24,
      child: Stack(
        children: [
          _downloading
              ? CircularProgressIndicator(
                  value: _received / _total,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(widget.opacity),
                  strokeWidth: 2.0,
                )
              : Container(),
          IconButton(
            padding: const EdgeInsets.all(0),
            constraints: const BoxConstraints(),
            onPressed: () {
              if (_downloading || awaitingCancel) {
                awaitingCancel = true;
              } else {
                _downloadImage(_showShareDialog);
              }
            },
            icon: Icon(
              _downloading ? Icons.stop : Icons.share,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(widget.opacity),
            ),
          )
        ],
      ),
    );
  }
}
