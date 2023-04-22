import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/widgets/error_image.dart';
import 'package:provider/provider.dart';

class ThumbnailImage extends StatelessWidget {
  final String apiPath;
  final BoxFit fit;
  final ImageWidgetBuilder? imageBuilder;

  const ThumbnailImage(this.apiPath, {Key? key, this.fit = BoxFit.contain, this.imageBuilder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    return CachedNetworkImage(
      imageUrl: apiPath,
      httpHeaders: model.getHeaders(),
      imageBuilder: imageBuilder,
      placeholder: (context, url) => SpinKitRipple(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      fadeOutDuration: const Duration(milliseconds: 500), // see https://github.com/Baseflow/flutter_cached_network_image/issues/716
      errorWidget: (context, url, error) {
        return const ErrorImage();
      },
      fit: fit,
      maxWidthDiskCache: 240,
      maxHeightDiskCache: 240,
    );
  }
}
