import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/widgets/expanded_section.dart';

/// Enables re-use of the ExpandedSection across multiple views by using a [GlobalKey].
class TopPicksContainer extends StatelessWidget {
  final bool expand;
  final Widget? child;
  final Key expandedKey = const GlobalObjectKey("TopPicksContainer");

  const TopPicksContainer({required this.expand, this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandedSection(
      expand: expand,
      key: expandedKey,
      child: SizedBox(
        height: 132,
        child: child,
      ),
    );
  }
}
