import 'package:flutter/material.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/selectable_card.dart';
import 'package:provider/provider.dart';

class SortOptionDialog extends StatelessWidget {
  const SortOptionDialog({super.key});

  List<Widget> _buildSortOptionItems(BuildContext context, SortOption selectedOption) {
    List<Widget> listItems = [];
    for (SortOption option in SortOption.values) {
      listItems.add(
        SizedBox(
          height: kMinInteractiveDimension,
          child: SelectableCard(
            isSelected: option == selectedOption,
            onSelected: () => context.read<HomeModel>().sortOption = option,
            title: Text(option.getDisplayName()),
          ),
        ),
      );
    }
    return listItems;
  }

  List<Widget> _buildSortOrderItems(BuildContext context, bool selectedSortOrder) {
    return [true, false]
        .map(
          (sortAscending) => SizedBox(
            height: kMinInteractiveDimension,
            child: SelectableCard(
              isSelected: sortAscending == selectedSortOrder,
              onSelected: () => context.read<HomeModel>().sortOrder = sortAscending,
              title: Text(sortAscending ? "Ascending" : "Descending"),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._buildSortOptionItems(context, context.select<HomeModel, SortOption>((it) => it.sortOption)),
        const Divider(thickness: 3),
        ..._buildSortOrderItems(context, context.select<HomeModel, bool>((it) => it.sortAscending)),
      ],
    );
  }
}
