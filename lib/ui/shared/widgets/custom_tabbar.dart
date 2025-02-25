import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/shared/widgets/autoscale_tabbarview/autoscale_tabbar_view.dart';

class TabData {
  final Tab title;
  final Widget content;

  TabData({required this.title, required this.content});
}

class CustomTabBarWidget extends TabBar {
  final List<TabData> tabData;

  CustomTabBarWidget({
    super.key,
    required this.tabData,
    super.isScrollable,
  }) : super(tabs: []);

  @override
  State<CustomTabBarWidget> createState() => _CustomTabBarWidgetState();
}

class _CustomTabBarWidgetState extends State<CustomTabBarWidget> with TickerProviderStateMixin {
  late TabController _tabController;

  static int activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = getTabController();
  }

  TabController getTabController() {
    return TabController(
      initialIndex: activeTab,
      length: widget.tabData.length,
      vsync: this,
    )..addListener(() {
        setState(() {
          activeTab = _tabController.index;
        });
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildLeftArrow(BuildContext context) {
    bool disabled = _tabController.index == 0;
    return InkWell(
      onTap: disabled ? null : () {
        _tabController.animateTo(_tabController.index - 1);
      },
      overlayColor: Theme.of(context).tabBarTheme.overlayColor,
      child: SizedBox(
        height: kTextTabBarHeight,
        width: kTextTabBarHeight,
        child: Icon(
          Icons.arrow_back_ios_new,
          color: disabled ? Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(100) : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget buildRightArrow(BuildContext context) {
    bool disabled = _tabController.index == widget.tabData.length - 1;
    return InkWell(
      onTap: disabled ? null : () {
        _tabController.animateTo(_tabController.index + 1);
      },
      overlayColor: Theme.of(context).tabBarTheme.overlayColor,
      child: SizedBox(
        height: kTextTabBarHeight,
        width: kTextTabBarHeight,
        child: Icon(
          Icons.arrow_forward_ios,
          color: disabled ? Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(100) : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: DefaultTabController(
        length: widget.tabData.length,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Material(
              elevation: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withAlpha(20),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
                child: Row(
                  children: [
                    buildLeftArrow(context),
                    Expanded(
                      child: TabBar(
                        tabAlignment: TabAlignment.fill,
                        dividerHeight: 0,
                        isScrollable: false,
                        controller: _tabController,
                        tabs: widget.tabData.map((tab) => tab.title).toList(),
                      ),
                    ),
                    buildRightArrow(context),
                  ],
                ),
              ),
            ),
            AutoScaleTabBarView(
              controller: _tabController,
              children: widget.tabData.map((tab) => tab.content).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
