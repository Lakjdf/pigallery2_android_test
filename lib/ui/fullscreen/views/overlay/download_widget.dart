import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/download_model.dart';
import 'package:provider/provider.dart';

class DownloadWidget extends StatelessWidget {
  final double opacity;

  const DownloadWidget(this.opacity, {super.key});

  @override
  Widget build(BuildContext context) {
    bool downloading = context.select((DownloadModel model) => model.downloading);
    return SizedBox(
      height: 24,
      width: 24,
      child: Stack(
        children: [
          downloading
              ? CircularProgressIndicator(
                  value: context.select((DownloadModel model) => model.progress),
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: opacity),
                  strokeWidth: 2.0,
                )
              : Container(),
          IconButton(
            padding: const EdgeInsets.all(0),
            constraints: const BoxConstraints(),
            onPressed: () {
              if (downloading) {
                context.read<DownloadModel>().cancel();
              } else {
                context.read<DownloadModel>().share();
              }
            },
            icon: Icon(
              downloading ? Icons.stop : Icons.share,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: opacity),
            ),
          )
        ],
      ),
    );
  }
}
