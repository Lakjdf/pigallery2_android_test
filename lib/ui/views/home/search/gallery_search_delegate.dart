import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/views/gallery_view.dart';
import 'package:provider/provider.dart';

class GallerySearchDelegate extends SearchDelegate<String> {
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
      IconButton(
        onPressed: () => query = "",
        icon: const Icon(Icons.clear),
      ),
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
    model.search(query);
    return GalleryView(1, () {});
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return GalleryView(1, () {});
  }
}