import 'package:flutter/material.dart';
import 'package:pigallery2_android/util/extensions.dart';

/// Displays the position & duration of the video as text.
class VideoProgressBarText extends StatefulWidget {
  const VideoProgressBarText({
    required this.initialValue,
    required this.stream,
    required this.opacity,
    super.key,
  });

  final Duration initialValue;
  final Stream<Duration> stream;
  final double opacity;

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
    Color onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Text(
      _duration.format(),
      style: TextStyle(color: onSurfaceVariant.withValues(alpha: widget.opacity)),
    );
  }
}
