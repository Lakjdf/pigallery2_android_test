import 'package:flutter/material.dart';

class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      widthFactor: 0.35,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 7.0,
        ),
        child: Container(
          height: 7.0,
          decoration: BoxDecoration(
            color: theme.dividerColor,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
    );
  }
}
