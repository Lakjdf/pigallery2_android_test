import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/home/views/home_view.dart';
import 'package:provider/provider.dart';

class FlattenDirButton extends StatelessWidget {
  const FlattenDirButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HomeModel model = context.read<HomeModel>();
        model.flattenDir();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: ((context) => HomeView(model.stackPosition)),
          ),
        );
      },
      icon: Icon(
        Ionicons.git_branch_outline,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
