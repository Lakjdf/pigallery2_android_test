import 'package:flutter/material.dart';

class FadeAnimation extends StatefulWidget {
  const FadeAnimation({super.key, this.child, required this.duration, this.curve = Curves.linear});

  final Widget? child;
  final Duration duration;
  final Curve curve;

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
    curve: Curves.easeOutQuart,
  );

  @override
  void initState() {
    super.initState();
    _controller.reverse(from: 1);
  }

  @override
  void deactivate() {
    _controller.stop();
    super.deactivate();
  }

  @override
  void didUpdateWidget(FadeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.reverse(from: 1);
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
