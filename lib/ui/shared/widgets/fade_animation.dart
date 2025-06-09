import 'package:flutter/material.dart';

class FadeAnimation extends StatefulWidget {
  const FadeAnimation({super.key, this.child, required this.duration, this.curve = Curves.easeOutQuart, this.reverse = true,});

  final Widget? child;
  final Duration duration;
  final Curve curve;
  final bool reverse;

  @override
  State createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: widget.duration,
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  @override
  void initState() {
    super.initState();
    if (widget.reverse) {
      _controller.reverse(from: 1);
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void deactivate() {
    _controller.stop();
    super.deactivate();
  }

  @override
  void didUpdateWidget(FadeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reverse) {
      _controller.reverse(from: 1);
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
