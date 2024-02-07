import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/app_bar/actions/sort_option_dialog.dart';

class SortOptionWidget extends StatelessWidget {
  const SortOptionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) {
            return const AlertDialog(
              title: Text("Sort By"),
              scrollable: true,
              content: SortOptionDialog(),
            );
          },
        );
      },
      icon: Icon(
        Icons.sort,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
