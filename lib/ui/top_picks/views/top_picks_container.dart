import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/shared/widgets/expanded_section.dart';

/// Enables re-use of the ExpandedSection across multiple views by using a [GlobalKey].
const Key expandedKey = GlobalObjectKey("TopPicksContainer");
class TopPicksContainer extends StatelessWidget {
  final bool expand;
  final Widget? child;

  const TopPicksContainer({required this.expand, this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandedSection(
      expand: expand,
      key: expandedKey, // required for closing animation
      child: SizedBox(
        height: 132,
        child: child,
      ),
    );
  }
}
