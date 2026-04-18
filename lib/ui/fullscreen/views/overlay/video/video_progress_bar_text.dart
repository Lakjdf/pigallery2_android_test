import 'package:flutter/material.dart';
import 'package:pigallery2_android/util/extensions.dart';

/// Displays the position & duration of the video as text.
class VideoProgressBarText extends StatefulWidget {
  const VideoProgressBarText({
    required this.initialValue,
    required this.stream,
    required this.opacity,
    this.color,
    super.key,
  });

  final Duration initialValue;
  final Stream<Duration> stream;
  final double opacity;
  final Color? color;

  @override
  State createState() => _VideoProgressBarTextState();
}

class _VideoProgressBarTextState extends State<VideoProgressBarText> {
  late Duration _duration = widget.initialValue;

  @override
  void initState() {
    super.initState();
    widget.stream.listen((event) {
      if (!mounted) return;
      setState(() {
        _duration = event;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color base = widget.color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Text(
      _duration.format(),
      style: TextStyle(
        color: base.withValues(alpha: widget.opacity),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}
