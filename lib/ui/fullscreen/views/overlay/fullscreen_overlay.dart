import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/fullscreen_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/photo_model.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video/video_controller_item.dart';
import 'package:pigallery2_android/ui/fullscreen/viewmodels/video_model.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/download_widget.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/floating_action_widget.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/video/video_controls.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/video/video_progress_bar.dart';
import 'package:pigallery2_android/ui/fullscreen/views/overlay/video/video_zoom_detector.dart';
import 'package:pigallery2_android/ui/shared/widgets/selector_guard.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:pigallery2_android/util/system_ui.dart';
import 'package:provider/provider.dart';

import 'media_info_bottom_sheet.dart';
import 'media_settings_bottom_sheet.dart';

class FullscreenOverlay extends StatefulWidget {
  final Widget child;
  final EdgeInsets viewPadding;

  const FullscreenOverlay({required this.child, required this.viewPadding, super.key});

  @override
  State<FullscreenOverlay> createState() => _FullscreenOverlayState();
}

class _FullscreenOverlayState extends State<FullscreenOverlay> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  bool controlsVisible = true;

  late double statusBarHeight;

  late double navigationBarHeight;

  @override
  void initState() {
    super.initState();
    statusBarHeight = widget.viewPadding.top;
    navigationBarHeight = widget.viewPadding.bottom;
    WidgetsBinding.instance.addObserver(this);
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && controlsVisible) {
        setState(() {
          controlsVisible = false;
        });
      } else if (!controlsVisible) {
        setState(() {
          controlsVisible = true;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateOrientation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Orientation? _lastOrientation;

  @override
  void didChangeMetrics() {
    updateOrientation();
  }

  /// Reset scale on orientation change
  void updateOrientation() {
    final currentOrientation = MediaQuery.of(context).orientation;
    if (_lastOrientation == null) {
      _lastOrientation = currentOrientation;
      return;
    }
    if (currentOrientation != _lastOrientation) {
      _lastOrientation = currentOrientation;
      Provider.of<VideoModel>(context, listen: false).videoScale = 1.0;
    }
  }

  void handleTap() {
    if (_animation.value == 1.0) {
      _controller.animateBack(0, curve: Curves.easeInQuart);
      SystemUi.hideSystemBars();
    } else {
      SystemUi.showSystemBars();
      _controller.forward();
    }
  }

  void rotateScreen(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
  }

  Widget buildVideoSeekBar(BuildContext context, double opacity) {
    return SelectorGuard<VideoModel, VideoControllerItem>(
      selector: (model) => model.videoControllerItem,
      condition: (item) => !item.hasError,
      then: (context, item) => Align(
        alignment: Alignment.bottomCenter,
        child: VideoProgressBar(key: ObjectKey(item), controller: item.controller, opacity: opacity),
      ),
    );
  }

  Widget buildTopBar(BuildContext context, Media item) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(item.metadata.date.toInt() * 1000);
    return Container(
      height: toolbarHeight + statusBarHeight,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
      child: Container(
        padding: EdgeInsets.fromLTRB(6, statusBarHeight, 6, statusBarHeight == 0 ? 0 : 6),
        height: toolbarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                item.name,
                overflow: TextOverflow.fade,
                maxLines: 1,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat("dd/MM/yyyy").format(dateTime),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  DateFormat("HH:mm:ss").format(dateTime),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget bigIconButton(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: kToolbarHeight,
          child: Icon(icon, size: 26, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget buildBottomBar(BuildContext context, Media item) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaY: 5, sigmaX: 5, tileMode: TileMode.clamp),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
          padding: EdgeInsets.only(bottom: navigationBarHeight),
          height: kBottomNavigationBarHeight + navigationBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DownloadWidget(),
              bigIconButton(Icons.color_lens_outlined, () {
                showModalBottomSheet(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (context) => MediaSettingsBottomSheet(),
                );
              }),
              bigIconButton(Icons.info_outline, () {
                showModalBottomSheet(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (context) => MediaInfoBottomSheet(item),
                );
              }),
              bigIconButton(Icons.screen_rotation, () => rotateScreen(context)),
              bigIconButton(Icons.close, () {
                _controller.value = 0.0;
                Navigator.maybePop(context, item);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFloatingHideOverlayWidget(BuildContext context, Media item) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) return SizedBox.shrink();
    return Selector<FullscreenModel, bool>(
      selector: (context, model) => model.hideDetailedOverlay,
      builder: (context, bool hideDetailedOverlay, child) {
        return FloatingActionWidget(
          icon: hideDetailedOverlay ? Icons.zoom_out_map_outlined : Icons.zoom_in_map_outlined,
          onPressed: () {
            context.read<FullscreenModel>().hideDetailedOverlay = !hideDetailedOverlay;
          },
        );
      },
    );
  }

  Widget buildFloatingMotionPhotoWidget(BuildContext context, Media item) {
    return SelectorGuard<PhotoModel, bool>(
      selector: (model) => model.stateOf(item).isMotionPhoto,
      then: (model, _) {
        return FloatingActionWidget(
          icon: Icons.motion_photos_paused,
          tooltip: "Long press the image to see the motion photo",
        );
      },
    );
  }

  Widget buildOverlayBars(BuildContext context) {
    return Selector<FullscreenModel, ({Media item, bool hideDetailedOverlay})>(
      selector: (context, model) => (item: model.currentItem, hideDetailedOverlay: model.hideDetailedOverlay),
      builder: (context, ({Media item, bool hideDetailedOverlay}) data, child) {
        bool showDetailedOverlay =
            MediaQuery.of(context).orientation == Orientation.portrait ||
            !data.item.isVideo ||
            !data.hideDetailedOverlay;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showDetailedOverlay)
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaY: 5, sigmaX: 5, tileMode: TileMode.clamp),
                  child: buildTopBar(context, data.item),
                ),
              ),
            Spacer(),
            if (data.item.isVideo) buildFloatingHideOverlayWidget(context, data.item),
            if (data.item.isImage) buildFloatingMotionPhotoWidget(context, data.item),
            if (data.item.isVideo) buildVideoSeekBar(context, 1.0),
            if (showDetailedOverlay) buildBottomBar(context, data.item),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Selector<VideoModel, VideoControllerItem?>(
          selector: (context, model) => model.videoControllerItem,
          builder: (context, controller, child) => controller == null
              ? GestureDetector(onTap: handleTap)
              : VideoZoomDetector(
                  videoControllerItem: controller,
                  child: VideoControls(key: ObjectKey(controller), controller, handleTap),
                ),
        ),
        IgnorePointer(
          ignoring: !controlsVisible,
          child: FadeTransition(
            opacity: _animation,
            child: Selector<FullscreenModel, double>(
              selector: (context, model) => model.opacity,
              builder: (context, opacity, child) => Opacity(opacity: opacity, child: buildOverlayBars(context)),
            ),
          ),
        ),
      ],
    );
  }
}
