import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/app_bar/actions/sort_option_button.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/gallery/gallery_view.dart';
import 'package:pigallery2_android/ui/app_bar/actions/fullscreen_toggle_button.dart';
import 'package:provider/provider.dart';

class GallerySearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.appBarTheme.backgroundColor,
        titleTextStyle: theme.textTheme.titleLarge,
        toolbarTextStyle: theme.textTheme.bodyMedium,
        iconTheme: theme.iconTheme,
      ),
      inputDecorationTheme: searchFieldDecorationTheme ??
          InputDecorationTheme(
            hintStyle: searchFieldStyle ?? theme.inputDecorationTheme.hintStyle,
            border: InputBorder.none,
          ),
    );
  }

  @override
  void close(BuildContext context, String result) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    model.stopSearch();
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    super.close(context, result);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      const FullscreenToggleAction(),
      const SortOptionWidget()
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, query),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    model.textSearch(query);
    return GalleryView(1, () {});
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return GalleryView(1, () {});
  }
}
