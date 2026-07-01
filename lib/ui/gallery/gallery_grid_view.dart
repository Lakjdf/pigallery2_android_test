import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pigallery2_android/data/storage/models/sort_option.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/app_bar/app_bar_scroll_sync.dart';
import 'package:pigallery2_android/ui/fullscreen/views/open_fullscreen.dart';
import 'package:pigallery2_android/ui/home/views/error_screen.dart';
import 'package:pigallery2_android/ui/home/views/refresh_wrapper.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/gallery/gallery_scrubber.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/gallery/directory_item.dart';
import 'package:pigallery2_android/ui/gallery/media_item.dart';
import 'package:pigallery2_android/ui/home/views/glass_nav_bar.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

class GalleryViewGridView extends StatefulWidget {
  final int stackPosition;
  final List<Item> items;
  final Widget? leading;

  GalleryViewGridView(this.stackPosition, this.items, {this.leading}) : super(key: ValueKey(items));

  @override
  State<GalleryViewGridView> createState() => _GalleryViewGridViewState();
}

class _GalleryViewGridViewState extends State<GalleryViewGridView> with TickerProviderStateMixin, AppBarScrollSync {
  late ScrollController _scrollController;
  late List<Item> items;
  int chunkSize = 100;

  @override
  ScrollController get appBarScrollController => _scrollController;

  @override
  void initState() {
    items = widget.items.take(chunkSize).toList();
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0.0);
    _scrollController.addListener(() {
      // adding items dynamically based on scroll position
      // otherwise GridView.builder initializes all widgets upfront, which may take a long time
      if (_scrollController.position.extentAfter < 500) {
        if (items.length < widget.items.length) {
          setState(() {
            items.addAll(widget.items.skip(items.length).take(chunkSize));
          });
        }
      }
      syncAppBarOffset();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => attachAppBar());
  }

  /// Total height of slivers above the grid: app bar + status bar + (optionally) top picks.
  double _getLeadingOffset(BuildContext context) {
    double offset = SystemUi.getPadding().top + toolbarHeight;
    if (widget.leading != null) {
      final showTopPicks = context.read<GlobalSettingsModel>().showTopPicks;
      final isUpToDateAndEmpty = context.read<TopPicksModel>().isUpToDateAndEmpty;
      if (showTopPicks && !isUpToDateAndEmpty) {
        offset += 132; // matches TopPicksContainer height
      }
    }
    return offset;
  }

  double _getImageHeight(BuildContext context) {
    GlobalSettingsModel settingsModel = context.read<GlobalSettingsModel>();
    int crossAxisCount = settingsModel.getGridCrossAxisCount(MediaQuery.of(context).orientation);
    int spacing = settingsModel.gridSpacing;
    double aspectRatio = settingsModel.gridAspectRatio;

    // total width decreases by (crossAxisCount - 1) * spacing
    // (crossAxisCount - 1) * spacing / crossAxisCount
    double widthDecrease = spacing - spacing / crossAxisCount;

    double imageWidth = MediaQuery.of(context).size.width / crossAxisCount;
    // subtract widthDecrease to keep square
    double correctedHeight = (imageWidth - widthDecrease) / aspectRatio;
    return correctedHeight;
  }

  void _scrollToShowedItem(BuildContext context, int gridIndex) {
    if (_scrollController.hasClients) {
      if (!_scrollController.position.hasContentDimensions) return;
      if (_scrollController.position.maxScrollExtent == 0) return; // too few elements to scroll

      GlobalSettingsModel settingsModel = context.read<GlobalSettingsModel>();
      int crossAxisCount = settingsModel.getGridCrossAxisCount(MediaQuery.of(context).orientation);
      int spacing = settingsModel.gridSpacing;

      int row = gridIndex ~/ crossAxisCount;
      double imageHeight = _getImageHeight(context);
      double topInset = SystemUi.getPadding().top + toolbarHeight;
      double bottomInset = GlassNavBarTheme.barHeight +
          GlassNavBarTheme.bottomPadding +
          MediaQuery.paddingOf(context).bottom;
      double imageTop = _getLeadingOffset(context) + row * (imageHeight + spacing);
      double imageBottom = imageTop + imageHeight;

      double pixels = _scrollController.position.pixels;
      double extent = _scrollController.position.extentInside;
      double visibleTop = pixels + topInset;
      double visibleBottom = pixels + extent - bottomInset;

      double error = imageHeight * 0.3; // how much space should be kept to top/bottom of screen
      double maxScroll = _scrollController.position.maxScrollExtent;

      if (imageTop - error < visibleTop) {
        // image is above visible
        double offset = (imageTop - error - topInset).clamp(0.0, maxScroll);
        _scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.ease);
      } else if (imageBottom + error > visibleBottom) {
        // image is below visible
        double offset = (imageBottom + error - extent + bottomInset).clamp(0.0, maxScroll);
        _scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.ease);
      }
    }
  }

  void openDirectory(BuildContext context, Directory directory) {
    context.read<GalleryModel>().addStack(directory);
    Navigator.of(context).pushNamed("", arguments: widget.stackPosition + 1);
  }

  void _openFullscreen(BuildContext context, List<Item> items, int totalIndex) {
    final media = items[totalIndex] as Media;
    final directoriesCount = items.whereType<Directory>().length;
    final mediaIndex = totalIndex - directoriesCount;
    openFullscreen(
      context,
      media,
      mediaIndex,
      onMediaIndexChanged: (idx) => _scrollToShowedItem(context, idx + directoriesCount),
    );
  }

  String? _labelForScrollOffset(
    double scrollOffset,
    double leadingOffset,
    double rowHeight,
    int crossAxisCount,
    SortType sortType,
  ) {
    if (sortType == SortType.random) return null;
    if (widget.items.isEmpty || rowHeight <= 0) return null;
    final gridOffset = (scrollOffset - leadingOffset).clamp(0.0, double.infinity);
    final row = (gridOffset / rowHeight).floor();
    final itemIndex = (row * crossAxisCount).clamp(0, widget.items.length - 1);
    final item = widget.items[itemIndex];
    return switch (sortType) {
      SortType.name => item.name.isNotEmpty ? item.name[0].toUpperCase() : null,
      SortType.size => _sizeLabel(item),
      SortType.date => DateFormat.yMMMM().format(
          DateTime.fromMillisecondsSinceEpoch(item.metadata.date.toInt() * 1000),
        ),
      SortType.random => null,
    };
  }

  String _sizeLabel(Item item) {
    if (item is Directory) {
      final count = item.metadata.size;
      return count == 1 ? "1 item" : "$count items";
    }
    return item.metadata.size.toHumanReadableFileSize();
  }

  @override
  Widget build(BuildContext context) {
    GlobalSettingsModel model = Provider.of<GlobalSettingsModel>(context);
    final topInset = SystemUi.getPadding().top + toolbarHeight;
    final bottomInset = MediaQuery.paddingOf(context).bottom +
        GlassNavBarTheme.barHeight +
        GlassNavBarTheme.bottomPadding +
        16;
    watchTabForAppBarSync(context);
    final sortType = context.read<GalleryModel>().stateOf(widget.stackPosition).sortOption.type;

    return OrientationBuilder(
      builder: (context, orientation) {
        final crossAxisCount = model.getGridCrossAxisCount(orientation);
        final spacing = model.gridSpacing.toDouble();
        final imageHeight = _getImageHeight(context);
        final rowHeight = imageHeight + spacing;
        final leadingOffset = _getLeadingOffset(context);

        return GalleryErrorScreen(
          // RefreshWrapper wraps the CustomScrollView directly — its
          // SmartRefresher needs a Scrollable child. The scrubber sits as a
          // sibling overlay on the right edge.
          child: Stack(
            children: [
              RefreshWrapper(
                child: CustomScrollView(
                  key: PageStorageKey(widget.stackPosition),
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: topInset)),
                    if (widget.leading != null) SliverToBoxAdapter(child: widget.leading),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        MediaQuery.paddingOf(context).left,
                        0,
                        MediaQuery.paddingOf(context).right,
                        bottomInset,
                      ),
                      sliver: SliverGrid.builder(
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: model.gridAspectRatio,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          Item item = items[index];
                          return item is Directory
                              ? DirectoryItem(
                                  dir: item,
                                  borderRadius: model.gridRoundedCorners,
                                  showDirectoryItemCount: model.showDirectoryItemCount,
                                  onTap: () => openDirectory(context, item),
                                )
                              : Builder(
                                  builder: (context) {
                                    final media = item as Media;
                                    final selectionActive = context.select<GalleryModel, bool>((galleryModel) => galleryModel.isSelectionActive);
                                    final isSelected = context.select<GalleryModel, bool>((galleryModel) => galleryModel.isMediaSelected(media));
                                    return MediaItem(
                                      item: media,
                                      borderRadius: model.gridRoundedCorners,
                                      isSelected: isSelected,
                                      selectionActive: selectionActive,
                                      onLongPress: () => context.read<GalleryModel>().enterSelectionMode(media),
                                      onTap: () {
                                        final galleryModel = context.read<GalleryModel>();
                                        if (selectionActive) {
                                          galleryModel.toggleSelection(media);
                                        } else {
                                          _openFullscreen(context, items, index);
                                        }
                                      },
                                    );
                                  },
                                );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: topInset,
                right: 0,
                bottom: bottomInset,
                child: GalleryScrubber(
                  scrollController: _scrollController,
                  labelBuilder: (offset) => _labelForScrollOffset(
                    offset,
                    leadingOffset,
                    rowHeight,
                    crossAxisCount,
                    sortType,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
