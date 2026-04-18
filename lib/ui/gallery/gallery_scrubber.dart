import 'package:flutter/material.dart';

/// Right-edge drag thumb for vertically scrolling content. While the user is
/// dragging, a floating bubble next to the thumb shows a contextual label for
/// the current scroll offset (month, first letter, file size, etc.). Outside
/// of drags, the thumb simply mirrors the current scroll offset.
class GalleryScrubber extends StatefulWidget {
  final ScrollController scrollController;

  /// Label to display in the bubble for a given scroll offset. Return null to
  /// suppress the bubble (e.g., when the current sort has no per-position
  /// label that would make sense to the user).
  final String? Function(double scrollOffset) labelBuilder;

  const GalleryScrubber({
    super.key,
    required this.scrollController,
    required this.labelBuilder,
  });

  @override
  State<GalleryScrubber> createState() => _GalleryScrubberState();
}

class _GalleryScrubberState extends State<GalleryScrubber> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant GalleryScrubber oldWidget) {
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
    if (maxScroll <= 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = constraints.maxHeight;
        final thumbY = _thumbYFromScroll(trackHeight);
        final bubbleCenterY = thumbY + _thumbHeight / 2;
        final label = widget.labelBuilder(_currentScroll());

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
              if (label != null)
                Positioned(
                  right: _trackRightInset + _thumbWidth + 16,
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
                              label,
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
