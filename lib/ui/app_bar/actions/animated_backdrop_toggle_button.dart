import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';

class AnimatedBackdropToggleButton extends StatelessWidget {
  const AnimatedBackdropToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 0.5).animate(Backdrop.of(context).animationController.view),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.expand_less),
        onPressed: Backdrop.of(context).fling,
      ),
    );
  }
}
