import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';
import 'package:pigallery2_android/ui/shared/widgets/fade_animation.dart';

class VideoControls extends StatefulWidget {
  const VideoControls(this.controller, this.onTap, {super.key});

  final VideoControllerItem controller;
  final VoidCallback onTap;

  @override
  State createState() {
    return _VideoControlsState();
  }
}

class _VideoControlsState extends State<VideoControls> {
  Widget imageFadeAnim = Container();
  Timer? _doubleTapTimer;

  VideoControllerItem get controller => widget.controller;

  /// The position of an input that has not been handled yet.
  int? newInputPosition;

  /// The position of the current input sequence.
  /// Input sequence refers to multiple taps at the same position in quick succession.
  int? currentInputPosition;

  /// The DateTime of the last input in the current input sequence.
  DateTime? currentInputDateTime;

  /// The number of tabs in the current input sequence.
  int tapCount = 0;

  Duration seekDuration = const Duration(seconds: 10);
  Duration fadeAnimationDuration = const Duration(milliseconds: 500);

  /// The maximum time from the end of the first tap to the start of the second
  /// tap in a double-tap gesture.
  Duration doubleTapTimeout = const Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    controller.errorStream().listen((_) {
      setState(() {});
    });
    controller.player.stream.buffering.listen((event) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
      });
    });
  }

  /// Determine whether the input has happened at the left, right or center.
  int getInputPosition(BuildContext context, TapUpDetails details) {
    double width = MediaQuery.of(context).size.width;
    double areaWidth = width / 3;
    double inputX = details.globalPosition.dx;
    if (inputX < 1 * areaWidth) return 0;
    if (inputX > 2 * areaWidth) return 2;
    return 1;
  }

  Widget buildScrim({double xTranslation = 0, double yTranslation = 0}) {
    Color surfaceVariant = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      width: 300,
      height: 300,
      transform: Matrix4.translationValues(xTranslation, yTranslation, 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            surfaceVariant.withValues(alpha: 0.15),
            surfaceVariant.withValues(alpha: 0.1),
            surfaceVariant.withValues(alpha: 0),
          ],
          stops: const [0, 0.44, 1],
        ),
      ),
    );
  }

  void handleSeekBackwards() {
    imageFadeAnim = FadeAnimation(
      duration: fadeAnimationDuration,
      curve: Curves.easeOutQuart,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          buildScrim(xTranslation: -110, yTranslation: -6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "- ${(tapCount - 1) * seekDuration.inSeconds}s",
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Icon(Icons.fast_rewind, size: 75, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
    Duration newPosition = controller.player.state.position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      controller.player.seek(newPosition);
    } else {
      controller.player.seek(Duration.zero);
    }
  }

  void handleSeekForwards() {
    imageFadeAnim = FadeAnimation(
      duration: fadeAnimationDuration,
      curve: Curves.easeOutQuart,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          buildScrim(xTranslation: 110, yTranslation: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "+ ${(tapCount - 1) * seekDuration.inSeconds}s",
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Icon(Icons.fast_forward, size: 75, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
    Duration newPosition = controller.player.state.position + const Duration(seconds: 10);
    if (newPosition < controller.player.state.duration) {
      controller.player.seek(newPosition);
    } else {
      controller.player.seek(Duration.zero);
    }
  }

  void handlePlayPause() {
    bool isPlaying = controller.player.state.playing;
    IconData iconData = isPlaying ? Icons.pause : Icons.play_arrow;

    imageFadeAnim = FadeAnimation(
      duration: fadeAnimationDuration,
      child: Icon(
        iconData,
        size: 100,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    if (isPlaying) {
      controller.player.pause();
    } else {
      controller.player.play();
    }
  }

  void handleSingleTap() => widget.onTap();

  void handleDoubleTap() {
    if (controller.hasError) return;
    switch (currentInputPosition) {
      case 0:
        handleSeekBackwards();
        break;
      case 2:
        handleSeekForwards();
        break;
      default:
        handlePlayPause();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) {
        newInputPosition = getInputPosition(context, details);
      },
      onTap: () {
        // Reset tapCount if too much time has passed or a different input has been made.
        bool sameInput = newInputPosition != null && currentInputPosition != null && newInputPosition == currentInputPosition;
        bool outdatedInput = currentInputDateTime == null || DateTime.now().difference(currentInputDateTime!).compareTo(fadeAnimationDuration) > 0;
        if (!sameInput || outdatedInput || (tapCount == 2 && newInputPosition == 1)) {
          tapCount = 0;
          imageFadeAnim = Container();
        }
        tapCount += 1;
        currentInputDateTime = DateTime.now();
        currentInputPosition = newInputPosition;
        newInputPosition = null;

        _doubleTapTimer?.cancel();
        if (tapCount == 1) {
          _doubleTapTimer = Timer(doubleTapTimeout, () {
            if (tapCount == 1) {
              handleSingleTap();
              tapCount = 0;
            }
          });
        } else {
          handleDoubleTap();
        }
      },
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  currentInputPosition == 0 ? imageFadeAnim : Container(),
                  currentInputPosition == 1 ? imageFadeAnim : Container(),
                  currentInputPosition == 2 ? imageFadeAnim : Container(),
                ],
              ),
            ),
            Center(
              child: controller.player.state.buffering && !controller.hasError
                  ? SpinKitRipple(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 0.5 *
                          (MediaQuery.of(context).orientation == Orientation.landscape
                              ? MediaQuery.of(context).size.height
                              : MediaQuery.of(context).size.width),
                    )
                  : null,
            ),
            Container(color: Colors.transparent),
          ],
        ),
      ),
    );
  }
}
