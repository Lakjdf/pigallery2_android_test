import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/download_model.dart';
import 'package:provider/provider.dart';

class DownloadWidget extends StatelessWidget {
  const DownloadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    bool downloading = context.select((DownloadModel model) => model.downloading);
    return Expanded(
      child: InkResponse(
        onTap: () {
          if (downloading) {
            context.read<DownloadModel>().cancel();
          } else {
            context.read<DownloadModel>().share();
          }
        },
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: kToolbarHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              downloading
                  ? CircularProgressIndicator(
                      value: context.select((DownloadModel model) => model.progress),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      strokeWidth: 2.0,
                    )
                  : Container(),
              Icon(
                downloading ? Icons.stop_outlined : Icons.share_outlined,
                size: 26,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
