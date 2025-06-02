import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ExtendedIndexedWidgetBuilder = Widget Function(BuildContext context, int index);

class HorizontalCarouselWrapper extends StatefulWidget {
  final int initialIndex;
  final int itemCount;
  final ExtendedIndexedWidgetBuilder builder;
  final Function(int)? onPageChanged;
  const HorizontalCarouselWrapper({
    required this.initialIndex,
    required this.itemCount,
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
    return SimpleKeyboardListener(
      leftPressed: () => _pageController.previousPage(duration: Duration(milliseconds: 600), curve: Curves.ease),
      rightPressed: () => _pageController.nextPage(duration: Duration(milliseconds: 600), curve: Curves.ease),
      child: PageView.builder(
          controller: _pageController,
          itemCount: widget.itemCount,
          itemBuilder: widget.builder,
          onPageChanged: widget.onPageChanged,
          physics: const FasterPageViewScrollPhysics(),
      ),
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
    mass: 1,
    stiffness: 402,
    damping: 40,
  );
}

/// Adds basic compatibility for desktop target
class SimpleKeyboardListener extends StatefulWidget {
  const SimpleKeyboardListener({
    super.key,
    required this.leftPressed,
    required this.rightPressed,
    required this.child,
  });

  final VoidCallback leftPressed;
  final VoidCallback rightPressed;
  final Widget child;

  @override
  State<SimpleKeyboardListener> createState() => _SimpleKeyboardListenerState();
}

class _SimpleKeyboardListenerState extends State<SimpleKeyboardListener> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_keyboardCallback);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyboardCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  bool _keyboardCallback(KeyEvent keyEvent) {
    if (keyEvent is! KeyDownEvent) return false;

    if (keyEvent.logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.leftPressed();
      return true;
    }
    if (keyEvent.logicalKey == LogicalKeyboardKey.arrowRight) {
      widget.rightPressed();
      return true;
    }
    return false;
  }
}
