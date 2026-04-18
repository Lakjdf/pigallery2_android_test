import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/gallery/timeline/month_sections.dart';

/// Right-edge drag thumb that jumps through the timeline. While the user is
/// dragging, a floating bubble next to the thumb shows the month they'd land
/// on. Outside of drags, the thumb simply mirrors the current scroll offset.
class TimelineScrubber extends StatefulWidget {
  final ScrollController scrollController;
  final List<double> sectionHeadOffsets;
  final double totalContentHeight;
  final List<TimelineSection> sections;
  final String Function(DateTime) formatMonth;

  const TimelineScrubber({
    super.key,
    required this.scrollController,
    required this.sectionHeadOffsets,
    required this.totalContentHeight,
    required this.sections,
    required this.formatMonth,
  });

  @override
  State<TimelineScrubber> createState() => _TimelineScrubberState();
}

class _TimelineScrubberState extends State<TimelineScrubber> with SingleTickerProviderStateMixin {
  static const double _trackWidth = 28;
  static const double _thumbWidth = 14;
  static const double _thumbHeight = 40;
  static const double _trackRightInset = 6;

  bool _dragging = false;
  late final AnimationController _bubbleController;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant TimelineScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _bubbleController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Repaint thumb position as the user scrolls via the grid.
    if (!mounted) return;
    setState(() {});
  }

  double _maxScroll() {
    if (!widget.scrollController.hasClients) return 0;
    final position = widget.scrollController.position;
    if (!position.hasContentDimensions) return 0;
    return position.maxScrollExtent;
  }

  double _currentScroll() {
    if (!widget.scrollController.hasClients) return 0;
    final position = widget.scrollController.position;
    if (!position.hasPixels) return 0;
    return position.pixels;
  }

  double _thumbYFromScroll(double trackHeight) {
    final maxScroll = _maxScroll();
    if (maxScroll <= 0) return 0;
    final thumbRange = (trackHeight - _thumbHeight).clamp(0.0, double.infinity);
    return (_currentScroll() / maxScroll) * thumbRange;
  }

  double _scrollFromThumbY(double thumbY, double trackHeight) {
    final maxScroll = _maxScroll();
    if (maxScroll <= 0) return 0;
    final thumbRange = (trackHeight - _thumbHeight).clamp(0.0, double.infinity);
    if (thumbRange <= 0) return 0;
    return (thumbY.clamp(0.0, thumbRange) / thumbRange) * maxScroll;
  }

  int _sectionIndexForScrollOffset(double scrollOffset) {
    if (widget.sectionHeadOffsets.isEmpty) return 0;
    int lo = 0;
    int hi = widget.sectionHeadOffsets.length - 1;
    int result = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (widget.sectionHeadOffsets[mid] <= scrollOffset) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }

  String _currentBubbleLabel() {
    if (widget.sections.isEmpty) return "";
    final idx = _sectionIndexForScrollOffset(_currentScroll());
    final clamped = idx.clamp(0, widget.sections.length - 1);
    return widget.formatMonth(widget.sections[clamped].month);
  }

  void _jumpToThumbY(double thumbY, double trackHeight) {
    final target = _scrollFromThumbY(thumbY, trackHeight);
    if (!widget.scrollController.hasClients) return;
    widget.scrollController.jumpTo(target);
  }

  void _beginDrag() {
    setState(() => _dragging = true);
    _bubbleController.forward();
  }

  void _endDrag() {
    setState(() => _dragging = false);
    _bubbleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxScroll = _maxScroll();
    if (maxScroll <= 0 || widget.sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = constraints.maxHeight;
        final thumbY = _thumbYFromScroll(trackHeight);
        final bubbleCenterY = thumbY + _thumbHeight / 2;

        return SizedBox(
          width: _trackWidth + _trackRightInset + 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Hit target spans the full right edge so the thumb is easy to grab.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragStart: (details) {
                    _beginDrag();
                    final localY = (details.localPosition.dy - _thumbHeight / 2)
                        .clamp(0.0, trackHeight - _thumbHeight);
                    _jumpToThumbY(localY, trackHeight);
                  },
                  onVerticalDragUpdate: (details) {
                    final localY = (details.localPosition.dy - _thumbHeight / 2)
                        .clamp(0.0, trackHeight - _thumbHeight);
                    _jumpToThumbY(localY, trackHeight);
                  },
                  onVerticalDragEnd: (_) => _endDrag(),
                  onVerticalDragCancel: _endDrag,
                ),
              ),
              Positioned(
                right: _trackRightInset,
                top: thumbY,
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: _thumbWidth,
                    height: _thumbHeight,
                    decoration: BoxDecoration(
                      color: _dragging
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(_thumbWidth / 2),
                      border: Border.all(
                        color: theme.colorScheme.surface.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: _trackRightInset + _thumbWidth + 8,
                top: bubbleCenterY - 18,
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: _bubbleController,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1).animate(
                        CurvedAnimation(parent: _bubbleController, curve: Curves.easeOut),
                      ),
                      alignment: Alignment.centerRight,
                      child: Material(
                        elevation: 4,
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Text(
                            _currentBubbleLabel(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
