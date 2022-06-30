import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/fullscreen_model.dart';
import 'package:provider/provider.dart';

class VerticalDismissWrapper extends StatefulWidget {
  const VerticalDismissWrapper({
    Key? key,
    required this.child,
    this.onOpacityChanged,
  }) : super(key: key);

  final Widget child;
  final Function(double)? onOpacityChanged;

  @override
  State createState() => _VerticalDismissWrapperState();
}

class _VerticalDismissWrapperState extends State<VerticalDismissWrapper> {
  double? initialPositionY = 0;
  double? currentPositionY = 0;
  double positionYDelta = 0;
  double opacity = 1;
  double disposeLimit = 100;

  late Duration animationDuration;

  @override
  void initState() {
    super.initState();
    animationDuration = Duration.zero;
  }

  void _startVerticalDrag(details) {
    setState(() {
      initialPositionY = details.globalPosition.dy;
    });
  }

  void _whileVerticalDrag(details) {
    setState(() {
      currentPositionY = details.globalPosition.dy;
      positionYDelta = currentPositionY! - initialPositionY!;
      setOpacity();
    });
    widget.onOpacityChanged!(opacity);
  }

  setOpacity() {
    double tmp = positionYDelta < 0 ? 1 - ((positionYDelta / 300) * -1) : 1 - (positionYDelta / 300);

    if (tmp > 1) {
      opacity = 1;
    } else if (tmp < 0) {
      opacity = 0;
    } else {
      opacity = tmp;
    }
  }

  _endVerticalDrag(DragEndDetails details) {
    if (positionYDelta > disposeLimit || positionYDelta < -disposeLimit) {
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
    return GestureDetector(
      onVerticalDragStart: (details) => _startVerticalDrag(details),
      onVerticalDragUpdate: (details) => _whileVerticalDrag(details),
      onVerticalDragEnd: (details) => _endVerticalDrag(details),
      child: Container(
        color: Colors.black.withOpacity(opacity),
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: Stack(
          children: <Widget>[
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
    );
  }
}
