import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:provider/provider.dart';

class SortOptionsWidget extends StatelessWidget {
  const SortOptionsWidget({super.key});

  PopupMenuItem<dynamic> _buildPopupItem(dynamic thisValue, dynamic selectedValue, String name) {
    return PopupMenuItem(
      value: thisValue,
      padding: const EdgeInsets.all(0),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -3),
        horizontalTitleGap: 0,
        title: Text(name),
        trailing: IgnorePointer(
          child: Radio(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4),
            value: thisValue,
            groupValue: selectedValue,
            onChanged: null,
          ),
        ),
      ),
    );
  }

  PopupMenuButton _buildSortOptions(BuildContext context, HomeModel model) {
    return PopupMenuButton<dynamic>(
      icon: Icon(
        Icons.sort,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onSelected: (dynamic option) {
        if (option is SortOption) {
          model.sortOption = option;
        } else {
          model.sortOrder = option;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<dynamic>>[
        ...SortOption.values.map((e) => _buildPopupItem(e, model.sortOption, e.getDisplayName())),
        const PopupMenuDivider(),
        _buildPopupItem(true, model.sortAscending, "Ascending"),
        _buildPopupItem(false, model.sortAscending, "Descending"),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    return _buildSortOptions(context, model);
  }
}