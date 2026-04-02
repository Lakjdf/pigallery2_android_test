import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:provider/provider.dart';

class GlassNavBarTheme {
  static const double barHeight = 42;
  static const double barRadius = 36;
  static const double iconSize = 28;
  static const double iconWidth = 54;
  static const double iconSpacing = 8;
  static const double bottomPadding = 24;

  static Color getGlassColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(0);

  static Color getBorderColor(BuildContext context) => Theme.of(context).colorScheme.onSurface.withAlpha(90);

  static Color getRippleColor(BuildContext context) => Theme.of(context).colorScheme.onSurface.withAlpha(60);

  static Color getIconColor(BuildContext context) => Theme.of(context).colorScheme.onSurface;
}

class _GlassBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(GlassNavBarTheme.barRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: GlassNavBarTheme.getGlassColor(context),
            borderRadius: BorderRadius.circular(GlassNavBarTheme.barRadius),
            border: Border.all(color: GlassNavBarTheme.getBorderColor(context), width: 2),
          ),
        ),
      ),
    );
  }
}

class GlassNavBar extends StatelessWidget {
  final List<IconData> tabIcons;
  final List<IconData> actions;
  final ValueChanged<int>? onTap;

  const GlassNavBar({
    super.key,
    required this.tabIcons,
    this.actions = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      left: false,
      right: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GlassNavBarContent(icons: tabIcons),
          if (actions.isNotEmpty) SizedBox(width: 16),
          if (actions.isNotEmpty) _GlassNavBarSimple(icons: actions, onTap: onTap!),
        ],
      ),
    );
  }
}

class _GlassNavBarSimple extends StatefulWidget {
  final List<IconData> icons;
  final ValueChanged<int> onTap;

  const _GlassNavBarSimple({required this.icons, required this.onTap});

  @override
  State<_GlassNavBarSimple> createState() => _GlassNavBarSimpleState();
}

class _GlassNavBarSimpleState extends State<_GlassNavBarSimple> {
  double? pointerX;

  int get iconCount => widget.icons.length;

  double get barWidth {
    final double totalSpacing = GlassNavBarTheme.iconSpacing * (iconCount + 1);
    return iconCount * GlassNavBarTheme.iconWidth + totalSpacing;
  }

  int _calculateScrollProgressFromPointerX(double pointerX) {
    final scrollProgress =
        (pointerX - GlassNavBarTheme.iconSpacing - (GlassNavBarTheme.iconWidth / 2)) /
        (GlassNavBarTheme.iconWidth + GlassNavBarTheme.iconSpacing);
    return scrollProgress.round();
  }

  int _calculateIndexFromPointerX(double pointerX) {
    final scrollProgress =
        (pointerX - GlassNavBarTheme.iconSpacing - (GlassNavBarTheme.iconWidth / 2)) /
        (GlassNavBarTheme.iconWidth + GlassNavBarTheme.iconSpacing);
    return scrollProgress.clamp(0.0, (widget.icons.length - 1).toDouble()).round();
  }

  double _calculateRippleCenterXFromIndex(int index) {
    final double totalSpacing = GlassNavBarTheme.iconSpacing * (widget.icons.length + 1);
    final double barWidth = widget.icons.length * GlassNavBarTheme.iconWidth + totalSpacing;
    final double iconSpacing = barWidth / widget.icons.length;
    return GlassNavBarTheme.iconSpacing + (index * iconSpacing) + (GlassNavBarTheme.iconWidth / 2);
  }

  void _onPointerDown(PointerDownEvent event) {
    final index = _calculateIndexFromPointerX(event.localPosition.dx);
    setState(() {
      pointerX = _calculateRippleCenterXFromIndex(index);
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    final index = _calculateIndexFromPointerX(event.localPosition.dx);
    setState(() {
      pointerX = _calculateRippleCenterXFromIndex(index);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.localPosition.dy.abs() < GlassNavBarTheme.barHeight) {
      final tabProgress = _calculateScrollProgressFromPointerX(event.localPosition.dx);
      if (tabProgress >= 0 && tabProgress < widget.icons.length) {
        widget.onTap(tabProgress.round());
      }
    }
    setState(() {
      pointerX = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: GlassNavBarTheme.bottomPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: GlassNavBarTheme.barHeight,
              width: barWidth,
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                onPointerMove: _onPointerMove,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _GlassBackground(),
                    _buildRippleLayer(),
                    _buildSimpleIconsRow(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRippleLayer() {
    final double? posX = pointerX;
    if (posX == null) return const SizedBox.shrink();

    final double centerY = GlassNavBarTheme.barHeight / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(GlassNavBarTheme.barRadius),
      child: CustomPaint(
        size: Size.infinite,
        painter: _RipplePainter(
          centerX: posX,
          centerY: centerY,
          rippleColor: GlassNavBarTheme.getRippleColor(context),
        ),
      ),
    );
  }

  Widget _buildSimpleIconsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.icons.length, (i) {
        return SizedBox(
          width: GlassNavBarTheme.iconWidth,
          height: GlassNavBarTheme.barHeight,
          child: Center(
            child: Icon(
              widget.icons[i],
              color: GlassNavBarTheme.getIconColor(context),
              size: GlassNavBarTheme.iconSize,
            ),
          ),
        );
      }),
    );
  }
}

class _GlassNavBarContent extends StatefulWidget {
  final List<IconData> icons;

  const _GlassNavBarContent({required this.icons});

  @override
  State<_GlassNavBarContent> createState() => _GlassNavBarContentState();
}

class _GlassNavBarContentState extends State<_GlassNavBarContent> {
  double _currentPointerLocalX = 0;
  bool _isDragging = false;

  int get iconCount => widget.icons.length;

  double get barWidth {
    final double totalSpacing = GlassNavBarTheme.iconSpacing * (iconCount + 1);
    return iconCount * GlassNavBarTheme.iconWidth + totalSpacing;
  }

  double _calculateScrollProgressFromPointerX(double pointerX) {
    final tabProgress =
        (pointerX - GlassNavBarTheme.iconSpacing - (GlassNavBarTheme.iconWidth / 2)) /
        (GlassNavBarTheme.iconWidth + GlassNavBarTheme.iconSpacing);
    return tabProgress.clamp(0.0, (widget.icons.length - 1).toDouble());
  }

  double _calculateRippleCenterXFromScrollProgress(double scrollProgress) {
    return GlassNavBarTheme.iconSpacing +
        scrollProgress * (GlassNavBarTheme.iconWidth + GlassNavBarTheme.iconSpacing) +
        (GlassNavBarTheme.iconWidth / 2);
  }

  /// Calculates the scale factor for an icon based on its distance from the focused tab
  double _calculateIconScaleFactor(double distance) {
    return 0.67 + (0.33 * (1.0 - distance).clamp(0, 1).abs());
  }

  void _handlePointerDown(PointerDownEvent event) {
    _isDragging = true;
    _currentPointerLocalX = event.localPosition.dx;
    final scrollProgress = _calculateScrollProgressFromPointerX(event.localPosition.dx).round().toDouble();
    context.read<TabNavigatorModel>().navigateTo(scrollProgress);
    setState(() {});
  }

  void _handlePointerUp(PointerUpEvent event) {
    _isDragging = false;
    setState(() {});
  }

  void _handleDragUpdate(double dx) {
    _currentPointerLocalX = dx;
    final scrollProgress = _calculateScrollProgressFromPointerX(dx);
    context.read<TabNavigatorModel>().navigateTo(scrollProgress);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: GlassNavBarTheme.bottomPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: GlassNavBarTheme.barHeight,
              width: barWidth,
              child: Listener(
                onPointerDown: (event) => _handlePointerDown(event),
                onPointerUp: _handlePointerUp,
                child: GestureDetector(
                  onHorizontalDragStart: (details) => _handleDragUpdate(details.localPosition.dx),
                  onHorizontalDragUpdate: (details) => _handleDragUpdate(details.localPosition.dx),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _GlassBackground(),
                      _buildRippleLayer(),
                      _buildAnimatedIconsRow(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRippleLayer() {
    return Consumer<TabStateModel>(
      builder: (context, tabStateModel, _) {
        final double centerY = GlassNavBarTheme.barHeight / 2;
        final double centerX = _isDragging
            ? _currentPointerLocalX
            : _calculateRippleCenterXFromScrollProgress(tabStateModel.currentScroll.clamp(0.0, iconCount - 1.0));

        return ClipRRect(
          borderRadius: BorderRadius.circular(GlassNavBarTheme.barRadius),
          child: CustomPaint(
            size: Size.infinite,
            painter: _RipplePainter(
              centerX: centerX,
              centerY: centerY,
              rippleColor: GlassNavBarTheme.getRippleColor(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIconsRow() {
    return Consumer<TabStateModel>(
      builder: (context, tabStateModel, _) {
        final double scrollProgress = tabStateModel.currentScroll.clamp(0.0, iconCount - 1.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          spacing: GlassNavBarTheme.iconSpacing,
          children: List.generate(widget.icons.length, (i) {
            final double distance = (i - scrollProgress).abs();
            final double scaleFactor = _calculateIconScaleFactor(distance);

            return SizedBox(
              width: GlassNavBarTheme.iconWidth,
              height: GlassNavBarTheme.barHeight,
              child: Center(
                child: Transform.scale(
                  scale: scaleFactor,
                  child: Icon(
                    widget.icons[i],
                    color: GlassNavBarTheme.getIconColor(context),
                    size: GlassNavBarTheme.iconSize,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  static const double maxRadius = 40;
  static const double blur = 12;

  final double centerX;
  final double centerY;
  final Color rippleColor;

  _RipplePainter({
    required this.centerX,
    required this.centerY,
    required this.rippleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint ripplePaint = Paint()
      ..color = rippleColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    canvas.drawCircle(Offset(centerX, centerY), maxRadius, ripplePaint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.centerX != centerX || oldDelegate.centerY != centerY || oldDelegate.rippleColor != rippleColor;
  }
}
