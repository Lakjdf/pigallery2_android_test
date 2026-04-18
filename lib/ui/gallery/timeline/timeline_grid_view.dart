import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/app_bar/app_bar_scroll_sync.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_model.dart';
import 'package:pigallery2_android/ui/fullscreen/views/open_fullscreen.dart';
import 'package:pigallery2_android/ui/gallery/directory_item.dart';
import 'package:pigallery2_android/ui/gallery/media_item.dart';
import 'package:pigallery2_android/ui/gallery/timeline/month_sections.dart';
import 'package:pigallery2_android/ui/gallery/timeline/timeline_scrubber.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/home/views/error_screen.dart';
import 'package:pigallery2_android/ui/home/views/glass_nav_bar.dart';
import 'package:pigallery2_android/ui/home/views/refresh_wrapper.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

/// Chronological, month-grouped view of a date-sorted item list. Directory
/// tiles (if any) render above the first month header; the app bar subtitle
/// only publishes once the user has scrolled past them. Pairs with
/// [TimelineScrubber] on the right edge.
class TimelineGridView extends StatefulWidget {
  final int stackPosition;
  final List<Item> items;

  TimelineGridView(this.stackPosition, this.items) : super(key: ValueKey(items));

  @override
  State<TimelineGridView> createState() => _TimelineGridViewState();
}

class _TimelineGridViewState extends State<TimelineGridView> with TickerProviderStateMixin, AppBarScrollSync {
  static const double _headerHeight = 48;
  /// Scroll distance (from the first month header) over which the title/date
  /// prominence swap completes. Short on purpose — the transition has two
  /// stable endpoints and lingering mid-way reads as a layout glitch.
  static const double _subtitleTransitionRange = 80;

  late ScrollController _scrollController;
  late List<TimelineSection> _sections;
  late List<Media> _flatMedia;
  late List<Directory> _directories;
  AppBarModel? _appBarModel;
  TabStateModel? _tabStateModel;
  TabEntry? _myTab;

  /// Cumulative vertical distance from the start of the section area to the
  /// top of section `i`'s header. When directories precede the month grid,
  /// these offsets already include the directory-grid height.
  List<double> _sectionHeadOffsets = const [];
  double _totalContentHeight = 0;

  @override
  ScrollController get appBarScrollController => _scrollController;

  @override
  void initState() {
    super.initState();
    _directories = widget.items.whereType<Directory>().toList();
    _flatMedia = widget.items.whereType<Media>().toList();
    _sections = groupByMonth(_flatMedia);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      attachAppBar();
      _updateCurrentSection(0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appBarModel = context.read<AppBarModel>();
    _myTab ??= context.read<TabEntry>();
    final tabStateModel = context.read<TabStateModel>();
    if (tabStateModel != _tabStateModel) {
      _tabStateModel?.removeListener(_onTabStateChanged);
      tabStateModel.addListener(_onTabStateChanged);
      _tabStateModel = tabStateModel;
    }
  }

  /// Re-publish the subtitle when this tab becomes active. Registered after
  /// [AppBarModel]'s own tab-state listener (which runs at app init), so our
  /// publish always executes *after* AppBarModel clears the stale subtitle —
  /// avoiding a race where the clear wins and the bar stays blank until the
  /// next scroll tick.
  void _onTabStateChanged() {
    if (!mounted) return;
    if (_tabStateModel?.currentTab != _myTab) return;
    _updateCurrentSection(_scrollController.hasClients ? _scrollController.position.pixels : 0);
  }

  @override
  void didUpdateWidget(covariant TimelineGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) {
      _directories = widget.items.whereType<Directory>().toList();
      _flatMedia = widget.items.whereType<Media>().toList();
      _sections = groupByMonth(_flatMedia);
      _sectionHeadOffsets = const [];
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabStateModel?.removeListener(_onTabStateChanged);
    _appBarModel?.setSubtitle(null);
    _appBarModel?.setSubtitleProgress(0);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    syncAppBarOffset();
    _updateCurrentSection(_scrollController.position.pixels);
  }

  void _updateCurrentSection(double scrollOffset) {
    if (_sections.isEmpty || _sectionHeadOffsets.isEmpty) {
      _appBarModel?.setSubtitle(null);
      _appBarModel?.setSubtitleProgress(0);
      return;
    }
    final transitionStart = _sectionHeadOffsets.first;
    // While the viewport is still inside the leading directory block, don't
    // publish a month — there isn't one yet. The first section head offset
    // is exactly the directory grid's height.
    if (scrollOffset < transitionStart) {
      _appBarModel?.setSubtitle(null);
      _appBarModel?.setSubtitleProgress(0);
      return;
    }
    final index = _sectionIndexForScrollOffset(scrollOffset);
    _appBarModel?.setSubtitle(_formatMonth(_sections[index].month));
    // When there are no directories, transitionStart is 0 — so offset 0 maps
    // to progress 0 and the title stays prominent until the user scrolls.
    final progress = (scrollOffset - transitionStart) / _subtitleTransitionRange;
    _appBarModel?.setSubtitleProgress(progress);
  }

  int _sectionIndexForScrollOffset(double scrollOffset) {
    int lo = 0;
    int hi = _sectionHeadOffsets.length - 1;
    int result = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_sectionHeadOffsets[mid] <= scrollOffset) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }

  String _formatMonth(DateTime month) => DateFormat.yMMMM().format(month);

  double _getImageHeight(BuildContext context) {
    final settings = context.read<GlobalSettingsModel>();
    final crossAxisCount = settings.getGridCrossAxisCount(MediaQuery.of(context).orientation);
    final spacing = settings.gridSpacing;
    final aspectRatio = settings.gridAspectRatio;
    final widthDecrease = spacing - spacing / crossAxisCount;
    final imageWidth = MediaQuery.of(context).size.width / crossAxisCount;
    return (imageWidth - widthDecrease) / aspectRatio;
  }

  double _getBottomInset(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom +
        GlassNavBarTheme.barHeight +
        GlassNavBarTheme.bottomPadding +
        16;
  }

  double _gridHeightForItems(int itemCount, int crossAxisCount, double imageHeight, double spacing) {
    if (itemCount == 0) return 0;
    final rows = (itemCount + crossAxisCount - 1) ~/ crossAxisCount;
    return rows * imageHeight + (rows - 1) * spacing;
  }

  void _recomputeSectionOffsets(BuildContext context, int crossAxisCount, double spacing) {
    final imageHeight = _getImageHeight(context);
    final leadingHeight = _gridHeightForItems(_directories.length, crossAxisCount, imageHeight, spacing);

    final offsets = <double>[];
    double cumulative = leadingHeight;
    for (final section in _sections) {
      offsets.add(cumulative);
      final gridHeight = _gridHeightForItems(section.items.length, crossAxisCount, imageHeight, spacing);
      cumulative += _headerHeight + gridHeight;
    }
    _sectionHeadOffsets = offsets;
    _totalContentHeight = cumulative;
  }

  void _openDirectory(BuildContext context, Directory directory) {
    context.read<GalleryModel>().addStack(directory);
    Navigator.of(context).pushNamed("", arguments: widget.stackPosition + 1);
  }

  void _openFullscreen(BuildContext context, int mediaIndex) {
    openFullscreen(
      context,
      _flatMedia[mediaIndex],
      mediaIndex,
      onMediaIndexChanged: (idx) => _scrollToMedia(context, idx),
    );
  }

  /// Scroll the grid so the media at [mediaIndex] is visible. Uses the same
  /// "30% margin" heuristic as the flat grid view. Section offsets already
  /// account for the leading directory block.
  void _scrollToMedia(BuildContext context, int mediaIndex) {
    if (!_scrollController.hasClients) return;
    if (!_scrollController.position.hasContentDimensions) return;
    if (_scrollController.position.maxScrollExtent == 0) return;
    if (_sectionHeadOffsets.isEmpty) return;

    final settings = context.read<GlobalSettingsModel>();
    final crossAxisCount = settings.getGridCrossAxisCount(MediaQuery.of(context).orientation);
    final spacing = settings.gridSpacing.toDouble();
    final imageHeight = _getImageHeight(context);

    int remaining = mediaIndex;
    int sectionIndex = 0;
    while (sectionIndex < _sections.length && remaining >= _sections[sectionIndex].items.length) {
      remaining -= _sections[sectionIndex].items.length;
      sectionIndex++;
    }
    if (sectionIndex >= _sections.length) return;

    final rowInSection = remaining ~/ crossAxisCount;
    final imageTop =
        _sectionHeadOffsets[sectionIndex] + _headerHeight + rowInSection * (imageHeight + spacing);
    final imageBottom = imageTop + imageHeight;

    final pixels = _scrollController.position.pixels;
    final extent = _scrollController.position.extentInside;
    final topInset = SystemUi.getPadding().top + toolbarHeight;
    final bottomInset = _getBottomInset(context);
    final visibleTop = pixels;
    final visibleBottom = pixels + extent - topInset - bottomInset;

    final error = imageHeight * 0.3;
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (imageTop - error < visibleTop) {
      final offset = (imageTop - error).clamp(0.0, maxScroll);
      _scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.ease);
    } else if (imageBottom + error > visibleBottom) {
      final offset = (imageBottom + error - extent + topInset + bottomInset).clamp(0.0, maxScroll);
      _scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.ease);
    }
  }

  Widget _buildSectionHeader(BuildContext context, TimelineSection section) {
    final theme = Theme.of(context);
    return SizedBox(
      height: _headerHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _formatMonth(section.month),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(
      GlobalSettingsModel settings, int crossAxisCount, double spacing) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: settings.gridAspectRatio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<GlobalSettingsModel>(context);
    final topInset = SystemUi.getPadding().top + toolbarHeight;
    final bottomInset = _getBottomInset(context);
    watchTabForAppBarSync(context);

    return OrientationBuilder(
      builder: (context, orientation) {
        final crossAxisCount = settings.getGridCrossAxisCount(orientation);
        final spacing = settings.gridSpacing.toDouble();
        _recomputeSectionOffsets(context, crossAxisCount, spacing);
        // Section head offsets may have changed with orientation/settings;
        // resync the subtitle to the current scroll position.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _updateCurrentSection(_scrollController.hasClients ? _scrollController.position.pixels : 0);
        });

        final horizontalPadding = EdgeInsets.symmetric(horizontal: MediaQuery.paddingOf(context).left);
        return GalleryErrorScreen(
          // RefreshWrapper must wrap the CustomScrollView directly — its
          // SmartRefresher needs a Scrollable child to drive fling physics.
          // The scrubber sits above as a sibling overlay.
          child: Stack(
            children: [
              RefreshWrapper(
                child: CustomScrollView(
                  key: PageStorageKey(widget.stackPosition),
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: topInset)),
                    if (_directories.isNotEmpty)
                      SliverPadding(
                        padding: horizontalPadding,
                        sliver: SliverGrid.builder(
                          itemCount: _directories.length,
                          gridDelegate: _gridDelegate(settings, crossAxisCount, spacing),
                          itemBuilder: (context, index) {
                            final dir = _directories[index];
                            return DirectoryItem(
                              dir: dir,
                              borderRadius: settings.gridRoundedCorners,
                              showDirectoryItemCount: settings.showDirectoryItemCount,
                              onTap: () => _openDirectory(context, dir),
                            );
                          },
                        ),
                      ),
                    for (int i = 0; i < _sections.length; i++) ...[
                      SliverToBoxAdapter(child: _buildSectionHeader(context, _sections[i])),
                      SliverPadding(
                        padding: horizontalPadding,
                        sliver: SliverGrid.builder(
                          itemCount: _sections[i].items.length,
                          gridDelegate: _gridDelegate(settings, crossAxisCount, spacing),
                          itemBuilder: (context, index) {
                            final media = _sections[i].items[index];
                            final absoluteIndex = _sections
                                .take(i)
                                .fold<int>(0, (acc, s) => acc + s.items.length) +
                                index;
                            return MediaItem(
                              item: media,
                              borderRadius: settings.gridRoundedCorners,
                              onTap: () => _openFullscreen(context, absoluteIndex),
                            );
                          },
                        ),
                      ),
                    ],
                    SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
                  ],
                ),
              ),
              Positioned(
                top: topInset,
                right: 0,
                bottom: bottomInset,
                child: TimelineScrubber(
                  scrollController: _scrollController,
                  sectionHeadOffsets: _sectionHeadOffsets,
                  totalContentHeight: _totalContentHeight,
                  sections: _sections,
                  formatMonth: _formatMonth,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
