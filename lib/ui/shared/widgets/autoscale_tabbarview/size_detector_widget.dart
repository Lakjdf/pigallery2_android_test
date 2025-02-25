import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SizeDetectorWidget extends StatefulWidget {
  /// Widget to measure the size of
  final Widget child;
  /// Invoked once the size has been detected, and every time it changes
  final ValueChanged<Size> onSizeDetect;

  const SizeDetectorWidget({
    super.key,
    required this.child,
    required this.onSizeDetect,
  });

  @override
  State<SizeDetectorWidget> createState() => _SizeDetectorWidgetState();
}

class _SizeDetectorWidgetState extends State<SizeDetectorWidget> {
  Size? _oldSize;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _detectSize());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SchedulerBinding.instance.addPostFrameCallback((_) => _detectSize());
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (notification) {
        if (notification is SizeChangedLayoutNotification) {
          SchedulerBinding.instance.addPostFrameCallback((_) => _detectSize());
        }
        return true;
      },
      child: SizeChangedLayoutNotifier(child: widget.child),
    );
  }

  void _detectSize() {
    if (!mounted) {
      return;
    }
    final size = context.size;
    if (_oldSize != size) {
      _oldSize = size;
      widget.onSizeDetect(size!);
    }
  }
}
