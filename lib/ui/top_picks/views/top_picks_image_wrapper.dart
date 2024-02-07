import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:provider/provider.dart';

/// Adds an (animated) border to the passed [image].
class TopPicksImageWrapper extends StatefulWidget {
  final Widget image;

  const TopPicksImageWrapper(this.image, {super.key});

  @override
  State<StatefulWidget> createState() => _TopPicksImageWrapperState();
}

class _TopPicksImageWrapperState extends State<TopPicksImageWrapper> with TickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return RotationTransition(
      // turns: CurveTween(curve: Curves.easeInToLinear).animate(_animationController),
      turns: Tween(begin: 0.0, end: 4.0).animate(_animationController),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.onSurfaceVariant,
              Theme.of(context).colorScheme.surfaceVariant,
            ],
            stops: const [0, 1],
          ),
          borderRadius: BorderRadius.circular(45),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = context.select<TopPicksModel, bool>((it) => it.isLoading);
    double height = 90;
    double borderWidth = 2;
    return SizedBox(
      height: height,
      child: CircleAvatar(
        radius: height / 2,
        backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        child: Stack(
          children: [
            if (isLoading) _buildAnimatedBackground(),
            Padding(
              padding: EdgeInsets.all(borderWidth),
              child: ClipOval(
                child: SizedBox(
                  height: height - 2 * borderWidth,
                  width: height - 2 * borderWidth,
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.passthrough,
                    children: [
                      Container(color: Theme.of(context).colorScheme.surfaceVariant),
                      widget.image,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
