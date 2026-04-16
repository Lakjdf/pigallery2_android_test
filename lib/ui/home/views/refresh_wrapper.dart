import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_navigator_model.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RefreshWrapper extends StatefulWidget {
  final Widget child;

  const RefreshWrapper({required this.child, super.key});

  @override
  State<RefreshWrapper> createState() => _RefreshWrapperState();
}

class _RefreshWrapperState extends State<RefreshWrapper> with TickerProviderStateMixin {
  late AnimationController _anicontroller, _scaleController;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    _anicontroller = AnimationController(vsync: this, duration: Duration(milliseconds: 2000));
    _scaleController = AnimationController(value: 0.0, vsync: this, upperBound: 1.0);
    super.initState();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scaleController.dispose();
    _anicontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      enablePullUp: false,
      enablePullDown: true,
      controller: _refreshController,
      onRefresh: () async {
        await context.read<TabNavigatorModel>().refresh();
        _refreshController.refreshCompleted();
      },
      header: CustomHeader(
        refreshStyle: RefreshStyle.Behind,
        onOffsetChange: (offset) {
          if (_refreshController.headerMode?.value != RefreshStatus.refreshing) {
            _scaleController.value = offset / 80.0;
          }
        },
        builder: (_, _) {
          return Container(
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: SystemUi.getPadding().top + toolbarHeight + 24),
            child: FadeTransition(
              opacity: _scaleController,
              child: ScaleTransition(
                scale: _scaleController,
                child: SpinKitSpinningLines(
                  size: 50.0,
                  controller: _anicontroller,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          );
        },
      ),
      child: widget.child,
    );
  }
}
