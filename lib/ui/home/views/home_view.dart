import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pigallery2_android/ui/app_bar/actions/server_settings_action.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_scroll_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/home/views/glass_nav_bar.dart';
import 'package:pigallery2_android/ui/home/views/home_view_front.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/ui/app_bar/home_app_bar.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: ((bool didPop, _) {
        onBackInvoked(context);
      }),
      child: Scaffold(
        primary: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            HomeViewFront(),
            // top scrim that bridges app bar and gallery so the title stays
            // readable when the bar background is hidden on scroll
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: SystemUi.getPadding().top + toolbarHeight + 50,
              child: IgnorePointer(
                child: Selector<AppBarScrollModel, bool>(
                  selector: (_, m) => m.offset > 10,
                  builder: (_, hasScrolled, child) => AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    opacity: hasScrolled ? 1.0 : 0.0,
                    child: child,
                  ),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color.fromARGB(160, 0, 0, 0), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            GlassNavBar(
              tabIcons: [
                Ionicons.image_outline,
                Ionicons.images_outline,
                Ionicons.globe_outline,
              ],
              actions: [Icons.settings],
              onTap: (i) async {
                if (i == 0) {
                  showServerSettings(context);
                }
              },
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(toolbarHeight + SystemUi.getPadding().top),
          child: HomeAppBar(),
        ),
      ),
    );
  }
}
