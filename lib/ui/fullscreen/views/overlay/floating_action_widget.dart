import 'package:flutter/material.dart';

class FloatingActionWidget extends StatelessWidget {
  final IconData icon;
  final void Function()? onPressed;
  final String? tooltip;

  const FloatingActionWidget({super.key, required this.icon, this.onPressed, this.tooltip});

  Widget buildIconButton(BuildContext context, void Function()? onPressed) {
    return IconButton(
      padding: const EdgeInsets.all(16),
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 24,
        shadows: <Shadow>[
          Shadow(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            blurRadius: 20,
            offset: Offset(0, 1),
          ),
        ],
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget buildTooltip({required Widget child}) {
    if (tooltip == null) return child;
    return Tooltip(
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 3),
      message: tooltip,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (tooltip == null) return buildIconButton(context, onPressed);
    assert(onPressed == null);
    return Tooltip(
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 3),
      message: tooltip,
      child: buildIconButton(context, null),
    );
  }
}
