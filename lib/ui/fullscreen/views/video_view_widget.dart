import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pigallery2_android/domain/models/item.dart' as models show Media;
import 'package:pigallery2_android/domain/repositories/media_repository.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/error_image.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

class VideoViewWidget extends StatefulWidget {
  final models.Media item;

  const VideoViewWidget({super.key, required this.item});

  @override
  State<VideoViewWidget> createState() => _VideoViewWidgetState();
}

class _VideoViewWidgetState extends State<VideoViewWidget> {
  VideoController? _videoController;
  bool error = false;
  bool isInitialized = false;
  late VideoModel videoModel;

  @override
  void dispose() {
    videoModel.unregisterMountedWidget(widget.item.id);
    super.dispose();
  }

  Widget buildPlaceholder() {
    return Stack(
      key: ValueKey(widget.item.id),
      fit: StackFit.passthrough,
      children: [
        ThumbnailImage(key: ObjectKey(widget.item), widget.item),
      ],
    );
  }

  void init() {
    if (isInitialized) return;
    isInitialized = true;

    MediaRepository repository = Provider.of<MediaRepository>(context, listen: false);
    VideoModel model = Provider.of<VideoModel>(context, listen: false);
    model.initializeVideoController(
      repository.getMediaApiPath(widget.item),
      repository.headers,
      widget.item.id,
    ).listen((VideoController? videoController) {
      if (!mounted || videoController == null) return;
      setState(() {
        _videoController = videoController;
      });
      videoController.player.stream.error.listen((event) {
        if (!mounted) return;
        setState(() {
          error = true;
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    videoModel = Provider.of<VideoModel>(context, listen: false);
    videoModel.registerMountedWidget(widget.item.id);
    init();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double imageHeight = MediaQuery.of(context).size.width * (widget.item.dimension.height / widget.item.dimension.width);

    if (error) {
      return const ErrorImage();
    } else if (!isInitialized || _videoController == null || _videoController?.player.platform?.videoControllerCompleter.isCompleted != true) {
      return buildPlaceholder();
    } else {
      return Center(
        child: Video(
          key: ValueKey("${widget.item.id}: $screenSize"), // has to include the screenSize; won't update on orientation changes otherwise
          controller: _videoController!,
          fit: BoxFit.contain,
          aspectRatio: widget.item.aspectRatio,
          controls: NoVideoControls,
          width: screenSize.width,
          height: imageHeight,
          alignment: Alignment.center
        ),
      );
    }
  }
}
