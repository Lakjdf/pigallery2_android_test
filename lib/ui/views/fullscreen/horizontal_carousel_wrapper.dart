import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:provider/provider.dart';

typedef ExtendedIndexedWidgetBuilder = Widget Function(BuildContext context, int index);

class HorizontalCarouselWrapper extends StatefulWidget {
  final int initialIndex;
  final ExtendedIndexedWidgetBuilder builder;
  final Function(int)? onPageChanged;
  const HorizontalCarouselWrapper({
    required this.initialIndex,
    required this.builder,
    this.onPageChanged,
    super.key,
  });

  @override
  State<HorizontalCarouselWrapper> createState() => _HorizontalCarouselWrapperState();
}

class _HorizontalCarouselWrapperState extends State<HorizontalCarouselWrapper> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    return PageView.builder(
      controller: _pageController,
      itemCount: model.currentState.media.length,
      itemBuilder: widget.builder,
      onPageChanged: widget.onPageChanged,
      physics: const FasterPageViewScrollPhysics(),
    );
  }
}

/// [ScrollPhysics] with a faster animation.
/// See https://github.com/flutter/flutter/issues/55103#issuecomment-747059541
class FasterPageViewScrollPhysics extends ScrollPhysics {
  const FasterPageViewScrollPhysics({super.parent});

  @override
  FasterPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FasterPageViewScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 50,
    stiffness: 100,
    damping: 0.8,
  );
}
