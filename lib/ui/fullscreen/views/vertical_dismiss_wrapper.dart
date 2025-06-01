import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:provider/provider.dart';

class VerticalDismissWrapper extends StatefulWidget {
  const VerticalDismissWrapper({
    super.key,
    required this.child,
    required this.background,
    this.onOpacityChanged,
  });

  final Widget child;
  final Widget? background;
  final Function(double)? onOpacityChanged;

  @override
  State createState() => _VerticalDismissWrapperState();
}

class _VerticalDismissWrapperState extends State<VerticalDismissWrapper> {
  double? initialPositionY = 0;
  double? currentPositionY = 0;
  double positionYDelta = 0;
  double opacity = 1;
  double disposeThreshold = 100;
  double transparentThreshold = 300;

  late Duration animationDuration;

  /// Ignore drag if 2+ pointers were used to start the drag
  bool ignoreDrag = false;

  /// Current count of pointers touching the screen
  int pointerCount = 0;

  @override
  void initState() {
    super.initState();
    animationDuration = Duration.zero;
  }

  void _startVerticalDrag(details) {
    if (pointerCount > 1) return;
    setState(() {
      initialPositionY = details.globalPosition.dy;
    });
  }

  void _whileVerticalDrag(details) {
    // ignore 2 pointer drag only in initial position
    if (pointerCount > 1 && positionYDelta == 0 || ignoreDrag) {
      ignoreDrag = true;
      return;
    }
    setState(() {
      currentPositionY = details.globalPosition.dy;
      positionYDelta = currentPositionY! - initialPositionY!;
      setOpacity();
    });
    widget.onOpacityChanged!(opacity);
  }

  setOpacity() {
    double tmp = positionYDelta < 0 ? 1 - ((positionYDelta / transparentThreshold) * -1) : 1 - (positionYDelta / transparentThreshold);

    if (tmp > 1) {
      opacity = 1;
    } else if (tmp < 0) {
      opacity = 0;
    } else {
      opacity = tmp;
    }
  }

  _endVerticalDrag(DragEndDetails details) {
    ignoreDrag = false;
    if (positionYDelta > disposeThreshold || positionYDelta < -disposeThreshold) {
      Navigator.of(context).maybePop(Provider.of<FullscreenModel>(context, listen: false).currentItem);
    } else {
      setState(() {
        animationDuration = const Duration(milliseconds: 300);
        opacity = 1;
        positionYDelta = 0;
      });
      widget.onOpacityChanged!(opacity);

      Future.delayed(animationDuration).then((_) {
        setState(() {
          animationDuration = Duration.zero;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<FullscreenModel, double>(
      selector: (context, model) => model.heroAnimationProgress,
      builder: (context, animationProgress, child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (PointerDownEvent event) => pointerCount++,
        onPointerUp: (PointerUpEvent event) => pointerCount--,
        child: GestureDetector(
          onVerticalDragStart: (details) => _startVerticalDrag(details),
          onVerticalDragUpdate: (details) => _whileVerticalDrag(details),
          onVerticalDragEnd: (details) => _endVerticalDrag(details),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: opacity * animationProgress,
                child: ClipRect(child: widget.background),
              ),
              AnimatedPositioned(
                duration: animationDuration,
                curve: Curves.fastOutSlowIn,
                top: 0 + positionYDelta,
                bottom: 0 - positionYDelta,
                left: 0,
                right: 0,
                child: widget.child,
              )
            ],
          ),
        ),
      ),
    );
  }
}
