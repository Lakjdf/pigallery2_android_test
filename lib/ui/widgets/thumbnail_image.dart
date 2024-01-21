import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/widgets/error_image.dart';
import 'package:provider/provider.dart';

class ThumbnailImage extends StatelessWidget {
  final String? apiPath;
  final BoxFit fit;
  final ImageWidgetBuilder? imageBuilder;

  const ThumbnailImage(this.apiPath, {super.key, this.fit = BoxFit.contain, this.imageBuilder});

  @override
  Widget build(BuildContext context) {
    if (apiPath == null) return const ErrorImage();
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    return CachedNetworkImage(
      imageUrl: apiPath!,
      httpHeaders: model.headers,
      imageBuilder: imageBuilder,
      placeholder: (context, url) => SpinKitRipple(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      fadeOutDuration: const Duration(milliseconds: 300),
      fadeOutCurve: Curves.easeOutCubic,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeInCurve: Curves.easeInCubic,
      errorWidget: (context, url, error) {
        return const ErrorImage();
      },
      fit: fit,
      maxWidthDiskCache: 240,
      maxHeightDiskCache: 240,
    );
  }
}
