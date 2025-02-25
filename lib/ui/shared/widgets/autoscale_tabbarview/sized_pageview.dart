import 'package:flutter/material.dart';

import 'size_detector_widget.dart';

class SizedPageView extends StatefulWidget {
  final List<Widget> children;
  final PageController pageController;
  final ScrollPhysics physics;

  const SizedPageView({
    super.key,
    required this.children,
    required this.pageController,
    required this.physics,
  });

  @override
  State<SizedPageView> createState() => _SizedPageViewState();
}

class _SizedPageViewState extends State<SizedPageView>
    with TickerProviderStateMixin {
  late List<double> _heights;
  late int _currentIndex = widget.pageController.initialPage;

  double get _currentHeight => _heights[_currentIndex];

  @override
  void initState() {
    super.initState();
    _heights = List.generate(widget.children.length, (index) => 0.0);

    widget.pageController.addListener(() {
      final newIndex = widget.pageController.page?.round();
      if (_currentIndex != newIndex) {
        if (!mounted) {
          return;
        }
        setState(() => _currentIndex = newIndex!);
      }
    });
  }

  @override
  void dispose() {
    widget.pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      curve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: _heights[0], end: _currentHeight),
      builder: (context, value, child) => SizedBox(height: value, child: child),
      child: PageView(
        controller: widget.pageController,
        physics: widget.physics,
        children: List.generate(widget.children.length, (index) {
          return OverflowBox(
            minHeight: 0,
            maxHeight: double.infinity,
            alignment: Alignment.topCenter,
            child: SizeDetectorWidget(
              onSizeDetect: (size) {
                if (mounted) {
                  setState(() => _heights[index] = size.height);
                }
              },
              child: Align(child: widget.children[index]),
            ),
          );
        }),
      ),
    );
  }
}
