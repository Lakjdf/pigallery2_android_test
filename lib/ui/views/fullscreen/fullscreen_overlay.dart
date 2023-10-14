import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/views/fullscreen/video/video_controls.dart';
import 'package:pigallery2_android/ui/views/fullscreen/video/video_seek_bar.dart';
import 'package:pigallery2_android/ui/views/fullscreen/download_widget.dart';
import 'package:provider/provider.dart';

class FullscreenOverlay extends StatefulWidget {
  final Widget child;

  const FullscreenOverlay({required this.child, Key? key}) : super(key: key);

  @override
  State<FullscreenOverlay> createState() => _FullscreenOverlayState();
}

class _FullscreenOverlayState extends State<FullscreenOverlay> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );
  bool controlsVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          controlsVisible = false;
        });
      } else if (status == AnimationStatus.completed) {
        setState(() {
          controlsVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    /// Reset scale on orientation change
    Provider.of<FullscreenModel>(context, listen: false).videoScale = 1.0;
  }

  bool isVideo(Media item) {
    return lookupMimeType(item.name)!.contains("video");
  }

  void handleTap() {
    if (_animation.value == 1.0) {
      _controller.animateBack(0.0);
    } else {
      _controller.forward();
    }
  }

  Widget buildAspectRatioToggle(BuildContext context, double controlsOpacity) {
    return Selector<FullscreenModel, bool>(
      selector: (context, model) => model.awaitingNewController,
      builder: (context, awaiting, child) => IconButton(
        padding: const EdgeInsets.all(0),
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(controlsOpacity),
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.aspect_ratio),
        onPressed: awaiting
            ? null
            : () {
                double aspectRatio = Provider.of<FullscreenModel>(context, listen: false).betterPlayerController!.getAspectRatio()!;
                double screenAspectRatio = MediaQuery.of(context).size.aspectRatio;
                double currentScale = Provider.of<FullscreenModel>(context, listen: false).videoScale;
                double newScale = 1;
                if (currentScale == 1) {
                  if (aspectRatio > screenAspectRatio) {
                    newScale = aspectRatio / screenAspectRatio;
                  } else {
                    newScale = screenAspectRatio / aspectRatio;
                  }
                }
                Provider.of<FullscreenModel>(context, listen: false).videoScale = newScale;
              },
      ),
    );
  }

  Widget buildControlsTop(BuildContext context, double controlsOpacity) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Selector<FullscreenModel, Media>(
        selector: (context, model) => model.currentItem,
        builder: (context, item, child) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              padding: const EdgeInsets.all(0),
              constraints: const BoxConstraints(),
              onPressed: () {
                _controller.value = 0.0;
                Navigator.maybePop(context, item);
              },
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(controlsOpacity),
              ),
            ),
            Expanded(
              child: Text(
                overflow: TextOverflow.fade,
                maxLines: 1,
                softWrap: false,
                item.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(controlsOpacity),
                        ) ??
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(controlsOpacity),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DownloadWidget(
                item: item,
                opacity: controlsOpacity,
                key: ObjectKey(item),
              ),
            ),
            !isVideo(item) ? Container() : buildAspectRatioToggle(context, controlsOpacity),
          ],
        ),
      ),
    );
  }

  Widget buildVideoSeekBar(BuildContext context, double opacity) {
    return Selector<FullscreenModel, BetterPlayerController?>(
      selector: (context, model) => model.betterPlayerController,
      builder: (context, controller, child) => controller == null
          ? Container()
          : Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 50,
                child: VideoSeekBar(
                  key: ObjectKey(controller),
                  controller: controller,
                  opacity: opacity,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Selector<FullscreenModel, double>(
          selector: (context, model) => model.videoScale,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: widget.child,
            );
          },
        ),
        Selector<FullscreenModel, BetterPlayerController?>(
          selector: (context, model) => model.betterPlayerController,
          builder: (context, controller, child) => controller == null
              ? GestureDetector(onTap: handleTap)
              : VideoControls(key: ObjectKey(controller), controller, handleTap),
        ),
        IgnorePointer(
          ignoring: !controlsVisible,
          child: FadeTransition(
            opacity: _animation,
            child: Stack(
              children: [
                Selector<FullscreenModel, double>(
                  selector: (context, model) => model.opacity,
                  builder: (context, controlsOpacity, child) {
                    return Container(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4 * controlsOpacity),
                      height: 40,
                      child: buildControlsTop(context, controlsOpacity),
                    );
                  },
                ),
                Selector<FullscreenModel, ({Media item, double opacity})>(
                  selector: (context, model) => (item: model.currentItem, opacity: model.opacity),
                  builder: (context, ({Media item, double opacity}) data, child) => !isVideo(data.item) ? Container() : buildVideoSeekBar(context, data.opacity),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
