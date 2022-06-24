import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/views/fullscreen/video/video_controls.dart';
import 'package:pigallery2_android/ui/views/fullscreen/video/video_seek_bar.dart';
import 'package:provider/provider.dart';

class FullscreenOverlay extends StatefulWidget {
  final Widget child;
  const FullscreenOverlay({required this.child, Key? key}) : super(key: key);

  @override
  State<FullscreenOverlay> createState() => _FullscreenOverlayState();
}

class _FullscreenOverlayState extends State<FullscreenOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Selector<FullscreenModel, BetterPlayerController?>(
          selector: (context, model) => model.betterPlayerController,
          builder: (context, controller, child) => controller == null
              ? GestureDetector(
                  onTap: handleTap,
                )
              : VideoControls(
                  key: ObjectKey(controller), controller, handleTap),
        ),
        FadeTransition(
          opacity: _animation,
          child: Stack(
            children: [
              Selector<FullscreenModel, double>(
                selector: (context, model) => model.opacity,
                builder: (context, controlsOpacity, child) {
                  return Container(
                    color: Colors.black.withOpacity(0.3 * controlsOpacity),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          IconButton(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _controller.value = 0.0;
                              Navigator.maybePop(
                                  context,
                                  Provider.of<FullscreenModel>(context,
                                          listen: false)
                                      .currentItem);
                            },
                            icon: Icon(
                              Icons.close,
                              color: Colors.white.withOpacity(controlsOpacity),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 0, 2),
                            child: Selector<FullscreenModel, Media>(
                              selector: (context, model) => model.currentItem,
                              builder: (context, item, child) => Text(
                                item.name,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color:
                                      Colors.white.withOpacity(controlsOpacity),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              !isVideo(Provider.of<FullscreenModel>(context, listen: true)
                      .currentItem)
                  ? Container()
                  : Selector<FullscreenModel, BetterPlayerController?>(
                      selector: (context, model) =>
                          model.betterPlayerController,
                      builder: (context, controller, child) =>
                          controller == null
                              ? Container()
                              : Align(
                                  alignment: Alignment.bottomCenter,
                                  child: SizedBox(
                                    height: 50,
                                    child: VideoSeekBar(
                                      key: ObjectKey(controller),
                                      controller,
                                    ),
                                  ),
                                ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
