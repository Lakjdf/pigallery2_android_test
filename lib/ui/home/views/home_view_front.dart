import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/views/home_tab_view.dart';
import 'package:pigallery2_android/ui/home/views/website_view.dart';
import 'package:pigallery2_android/ui/gallery/gallery_view.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_models_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/search/search_page.dart';
import 'package:pigallery2_android/ui/shared/widgets/keep_alive_widget.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:provider/provider.dart';

class HomeViewFront extends StatelessWidget {
  const HomeViewFront({super.key});

  List<Widget> _getTabs(BuildContext context) {
    return [
      KeepAliveWidget(child: HomeViewGalleryPage(position: 0)),
      KeepAliveWidget(child: HomeViewGalleryPage(position: 1)),
      KeepAliveWidget(child: HomeViewGalleryPage(position: 2)),
      KeepAliveWidget(child: WebsiteView()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = _getTabs(context);
    final tabState = context.read<TabStateModel>();
    return Stack(
      fit: StackFit.expand,
      children: [
        HomeTabView(
          initialIndex: tabState.currentTab.pos,
          itemCount: tabs.length,
          builder: (context, index) => tabs[index],
          onPageScroll: tabState.setTabScroll,
        ),
      ],
    );
  }
}

class HomeViewGalleryPage extends StatelessWidget {
  final int position;

  const HomeViewGalleryPage({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKeys[position]!,
      observers: [galleryRouteObservers[position]!],
      onGenerateRoute: (routeSettings) {
        int stackPosition =
            routeSettings.arguments as int? ??
            context.read<TabModelsProvider>().getModelByTab(position).stackPosition;
        return PageRouteBuilder(
          transitionDuration: fadeTransitionDuration,
          reverseTransitionDuration: fadeTransitionReverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          pageBuilder: (context, _, _) {
            Widget page;
            if (routeSettings.name == "search") {
              page = SearchPage(
                baseStackPosition: stackPosition,
                baseDirectory: context.read<TabModelsProvider>().getModelByTab(position).currentState.baseDirectory,
              );
            } else {
              page = GalleryView(stackPosition);
            }
            return Provider.value(
              value: TabEntry.fromPosition(position),
              builder: (context, child) => ChangeNotifierProvider<GalleryModel>.value(
                value: context.read<TabModelsProvider>().getModelByTab(position),
                child: page,
              ),
            );
          },
        );
      },
    );
  }
}
