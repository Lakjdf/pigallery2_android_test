import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/pigallery2_cache_manager.dart';
import 'package:pigallery2_android/domain/models/sprite_thumbnail_data.dart';
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/seeking/video_seek_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/seeking/video_seek_position.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/seeking/video_seek_preview_model.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:provider/provider.dart';

class VideoSeekPreview extends StatelessWidget {
  const VideoSeekPreview({super.key});

  Size _getPreviewSize(BuildContext context, Size previewSize) {
    Size size = MediaQuery.of(context).size;
    double longestSide = (size.width > size.height) ? size.width / 5 : size.width / 2.5;
    double scaleFactor = longestSide / previewSize.longestSide;
    return previewSize * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    SpriteRegion? preview = context.select<VideoSeekPreviewModel, SpriteRegion?>((model) => model.currentPreview);
    if (preview == null) return Container();

    final seekPosition = context.select<VideoSeekModel, VideoSeekPosition?>((model) => model.ongoingSeekPosition);
    if (seekPosition == null) return Container();

    final double borderWidth = 3;
    final previewSize = _getPreviewSize(context, preview.cropRect.size);
    final leftOffset = seekPosition.widgetPosition.dx - (previewSize.width + 2 * borderWidth) / 2;

    return Positioned(
      left: leftOffset,
      bottom: 62,
      child: Column(
        children: [
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 5,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VideoSeekThumbImage(
                previewSize,
                preview,
                key: ValueKey(seekPosition),
              ),
            ),
          ),
          Container(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 5,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(seekPosition.videoPosition.format()),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoSeekThumbImage extends StatelessWidget {
  final Size size;
  final SpriteRegion spriteRegion;

  const VideoSeekThumbImage(this.size, this.spriteRegion, {super.key});

  @override
  Widget build(BuildContext context) {
    MediaRepository repository = context.read<MediaRepository>();

    return CachedNetworkImage(
      key: ValueKey(spriteRegion.imagePath),
      imageUrl: spriteRegion.imagePath,
      imageBuilder: (context, imageProvider) {
        return ImageRectPreloader(imageProvider, spriteRegion.cropRect);
      },
      cacheManager: PiGallery2CacheManager.spriteThumbnails,
      httpHeaders: repository.headers,
      fadeInDuration: const Duration(milliseconds: 1),
      fadeOutDuration: const Duration(milliseconds: 1),
      width: size.width,
      height: size.height,
      fit: BoxFit.contain,
    );
  }
}

/// Only show the preview rect after the image is loaded.
class ImageRectPreloader extends StatefulWidget {
  const ImageRectPreloader(this.imageProvider, this.cropRect, {super.key});

  final ImageProvider imageProvider;
  final Rect cropRect;

  @override
  State createState() => _ImageRectPreloaderState();
}

class _ImageRectPreloaderState extends State<ImageRectPreloader> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    widget.imageProvider.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
        final image = imageInfo.image;
        setState(() {
          _image = image as ui.Image?;
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return Container();
    return CustomPaint(
      painter: ImageRectPainter(
        image: image,
        sourceRect: widget.cropRect,
        destinationRect: widget.cropRect,
      ),
    );
  }
}

class ImageRectPainter extends CustomPainter {
  final ui.Image image;
  final Rect sourceRect;
  final Rect destinationRect;

  ImageRectPainter({
    required this.image,
    required this.sourceRect,
    required this.destinationRect,
  });

  Rect _applyBoxFit(BoxFit fit, Size inputSize, Size outputSize) {
    final fittedSizes = applyBoxFit(fit, inputSize, outputSize);
    final scaleWidth = fittedSizes.destination.width / inputSize.width;
    final scaleHeight = fittedSizes.destination.height / inputSize.height;

    final width = inputSize.width * scaleWidth;
    final height = inputSize.height * scaleHeight;

    final dx = (outputSize.width - width) / 2;
    final dy = (outputSize.height - height) / 2;

    return Rect.fromLTWH(dx, dy, width, height);
  }

  Rect _alignRect(Rect rect, Size canvasSize, Alignment alignment) {
    final dx = (canvasSize.width - rect.width) * alignment.x / 2;
    final dy = (canvasSize.height - rect.height) * alignment.y / 2;
    return rect.translate(dx, dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    // Calculate source and destination rectangles
    final outputRect = _applyBoxFit(BoxFit.contain, Size(imageWidth, imageHeight), size);

    // Align the destination rectangle within the canvas
    final alignedRect = _alignRect(outputRect, size, Alignment.center);

    canvas.drawImageRect(
      image,
      sourceRect, // The portion of the image to draw
      alignedRect, // Where to draw it on the canvas
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
