import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/shared/widgets/expanded_section.dart';
import 'package:provider/provider.dart';

class BackLayer extends StatelessWidget {
  BackLayer({super.key});

  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    GlobalSettingsModel model = Provider.of<GlobalSettingsModel>(context, listen: false);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight) / 2.5,
      ),
      child: Scrollbar(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              ListTile(
                title: const Text("Dynamic Theme"),
                leading: Icon(Icons.palette, color: theme.colorScheme.onSurfaceVariant),
                trailing: Selector<GlobalSettingsModel, bool>(
                  selector: (context, model) => model.useMaterial3,
                  builder: (BuildContext context, useMaterial3, Widget? child) => Switch(
                    value: useMaterial3,
                    onChanged: (value) {
                      model.useMaterial3 = value;
                    },
                  ),
                ),
              ),
              ListTile(
                title: const Text("Rediscover This Day"),
                subtitle: const Text("Images from the same day, years go"),
                leading: Icon(Icons.image_search, color: theme.colorScheme.onSurfaceVariant),
                trailing: Selector<GlobalSettingsModel, bool>(
                  selector: (context, model) => model.showTopPicks,
                  builder: (BuildContext context, showTopPicks, Widget? child) => Switch(
                    value: showTopPicks,
                    onChanged: (value) {
                      model.showTopPicks = value;
                    },
                  ),
                ),
              ),
              Selector<GlobalSettingsModel, bool>(
                selector: (context, model) => model.showTopPicks,
                builder: (BuildContext context, showTopPicks, Widget? child) => ExpandedSection(
                  expand: showTopPicks,
                  child: Selector<GlobalSettingsModel, int>(
                    selector: (context, model) => model.topPicksDaysLength,
                    builder: (BuildContext context, daysLength, Widget? child) => ListTile(
                      title: Text((daysLength == 1) ? "Considering the same day" : "Considering the $daysLength most recent days"),
                      subtitle: Slider(
                        divisions: 13,
                        min: 1,
                        max: 14,
                        value: daysLength.toDouble(),
                        onChanged: (double value) => model.topPicksDaysLength = value.round(),
                        onChangeEnd: (value) => model.storeTopPicksDaysLength(),
                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                title: const Text("Directory Item Count"),
                leading: Icon(Icons.onetwothree, color: theme.colorScheme.onSurfaceVariant),
                trailing: Selector<GlobalSettingsModel, bool>(
                  selector: (context, model) => model.showDirectoryItemCount,
                  builder: (BuildContext context, showDirectoryItemCount, Widget? child) {
                    return Switch(
                      value: showDirectoryItemCount,
                      onChanged: (value) {
                        model.showDirectoryItemCount = value;
                      },
                    );
                  },
                ),
              ),
              ListTile(
                title: const Text("Items Per Row"),
                leading: Icon(Icons.grid_on, color: theme.colorScheme.onSurfaceVariant),
                trailing: Selector<GlobalSettingsModel, int>(
                    selector: (context, model) => model.getGridCrossAxisCount(MediaQuery.of(context).orientation),
                    builder: (BuildContext context, gridCrossAxisCount, Widget? child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: (gridCrossAxisCount > 1) ? () => model.storeGridCrossAxisCount(MediaQuery.of(context).orientation, gridCrossAxisCount - 1) : null,
                            icon: const Icon(Icons.remove),
                            disabledColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          Text(gridCrossAxisCount.toString()),
                          IconButton(
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: (gridCrossAxisCount < 10) ? () => model.storeGridCrossAxisCount(MediaQuery.of(context).orientation, gridCrossAxisCount + 1) : null,
                            icon: const Icon(Icons.add),
                            disabledColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                        ],
                      );
                    }),
              ),
              ListTile(
                leading: Icon(Icons.rounded_corner, color: theme.colorScheme.onSurfaceVariant),
                title: Row(
                  children: [
                    const Expanded(child: Text("Corner Radius")),
                    Expanded(
                      child: Selector<GlobalSettingsModel, int>(
                        selector: (context, model) => model.gridRoundedCorners,
                        builder: (context, gridRoundedCorners, child) => Slider(
                          divisions: 25,
                          min: 0,
                          max: 25,
                          value: gridRoundedCorners.toDouble(),
                          label: gridRoundedCorners.toString(),
                          onChanged: (double value) => model.gridRoundedCorners = value.round(),
                          onChangeEnd: (value) => model.storeGridRoundedCorners(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.grid_view, color: theme.colorScheme.onSurfaceVariant),
                title: Row(
                  children: [
                    const Expanded(child: Text("Spacing")),
                    Expanded(
                      child: Selector<GlobalSettingsModel, int>(
                        selector: (context, model) => model.gridSpacing,
                        builder: (context, gridSpacing, child) => Slider(
                          divisions: 25,
                          min: 0,
                          max: 25,
                          value: gridSpacing.toDouble(),
                          label: gridSpacing.toString(),
                          onChanged: (double value) => model.gridSpacing = value.round(),
                          onChangeEnd: (value) => model.storeGridSpacing(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.aspect_ratio, color: theme.colorScheme.onSurfaceVariant),
                title: Row(
                  children: [
                    const Expanded(child: Text("Aspect Ratio")),
                    Expanded(
                      child: Selector<GlobalSettingsModel, double>(
                        selector: (context, model) => model.gridAspectRatio,
                        builder: (context, gridAspectRatio, child) => Slider(
                          divisions: 10,
                          min: 0,
                          max: 1,
                          value: gridAspectRatio > 1 ? gridAspectRatio / 2 : gridAspectRatio - .5,
                          label: gridAspectRatio.toStringAsFixed(1),
                          onChanged: (double value) => model.gridAspectRatio = value > .5 ? 2 * value : .5 + value,
                          onChangeEnd: (_) => model.storeGridAspectRatio(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text("Preview while seeking videos"),
                subtitle: const Text("Requires PiGallery2 extension to be installed"),
                leading: Icon(Icons.swipe, color: theme.colorScheme.onSurfaceVariant),
                trailing: Selector<GlobalSettingsModel, bool>(
                  selector: (context, model) => model.showVideoSeekPreview,
                  builder: (BuildContext context, showVideoSeekPreview, Widget? child) {
                    return Switch(
                      value: showVideoSeekPreview,
                      onChanged: (value) {
                        model.showVideoSeekPreview = value;
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
