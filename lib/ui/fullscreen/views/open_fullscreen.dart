import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/pigallery2_image_cache.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/download_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_scroll_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/seeking/video_seek_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/seeking/video_seek_preview_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/fullscreen/views/fullscreen_view.dart';
import 'package:provider/provider.dart';

/// Pushes the fullscreen viewer rooted at [media] and streams the visible
/// media index back through [onMediaIndexChanged] so the caller can keep its
/// grid scrolled to the currently-displayed item.
///
/// [mediaIndex] is the index of [media] within the caller's flat media list
/// (directories excluded).
Future<void> openFullscreen(
  BuildContext context,
  Media media,
  int mediaIndex, {
  required void Function(int mediaIndex) onMediaIndexChanged,
}) async {
  final scrollModel = FullscreenScrollModel();
  final subscription = scrollModel.getCurrentIndex().listen((currentIndex) {
    if (!context.mounted) return;
    onMediaIndexChanged(currentIndex);
  });
  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, _) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: ((ctx) => DownloadModel(Provider.of<MediaRepository>(ctx, listen: false), media)),
            ),
            ChangeNotifierProvider(
              create: ((ctx) => FullscreenModel(
                [
                  Provider.of<VideoModel>(ctx, listen: false),
                  Provider.of<PhotoModel>(ctx, listen: false),
                  Provider.of<DownloadModel>(ctx, listen: false),
                ],
                mediaIndex,
                scrollModel,
              )),
            ),
            ChangeNotifierProvider(
              create: ((ctx) => VideoSeekPreviewModel(ctx.read(), ctx.read(), ctx.read())),
            ),
            ChangeNotifierProvider(
              create: ((ctx) => VideoSeekModel(ctx.read(), ctx.read())),
            ),
          ],
          child: FullscreenView(media),
        );
      },
    ),
  );
  subscription.cancel();
  PiGallery2ImageCache.fullResCache.clearLiveImages();
  PiGallery2ImageCache.fullResCache.clear();
}
