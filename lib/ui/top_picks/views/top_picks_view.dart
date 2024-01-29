import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/metadata.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/global_settings_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:pigallery2_android/ui/home/views/home_view.dart';
import 'package:pigallery2_android/ui/top_picks/views/top_picks_container.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

class TopPicksView extends StatefulWidget {
  const TopPicksView({super.key});

  @override
  State<TopPicksView> createState() => _TopPicksViewState();
}

class _TopPicksViewState extends State<TopPicksView> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  DateFormat format = DateFormat("dd/MM/yyyy");
  Key key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    final fetchTopPicks = Provider.of<TopPicksModel>(context, listen: false).fetchTopPicks;
    int daysLength = Provider.of<GlobalSettingsModel>(context, listen: false).topPicksDaysLength;
    SchedulerBinding.instance.addPostFrameCallback((_) => fetchTopPicks(daysLength));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openDirectory(BuildContext context, Directory directory) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    model.topPicksSearch(directory);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: ((context) => HomeView(1)),
      ),
    ).then((value) {
      model.stopSearch();
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    });
  }

  Widget _buildListView(int itemCount, Widget Function(BuildContext context, int pos) builder) {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(width: 20),
      scrollDirection: Axis.horizontal,
      itemCount: 2 + itemCount,
      padding: const EdgeInsets.only(top: 10),
      itemBuilder: (context, pos) {
        if (pos == 0 || pos == itemCount + 1) return const SizedBox.shrink();
        return builder(context, pos - 1);
      },
    );
  }

  DateTime _dateFromUnixTimestamp(int timestamp) {
    return DateUtils.dateOnly(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
  }

  Widget _buildCircularThumbnail(Item item) {
    double height = 90;
    double borderWidth = 2;
    return SizedBox(
      height: height,
      child: CircleAvatar(
        radius: height / 2,
        backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: ClipOval(
            child: SizedBox(
              height: height - 2 * borderWidth,
              width: height - 2 * borderWidth,
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.passthrough,
                children: [
                  Container(color: Theme.of(context).colorScheme.surfaceVariant),
                  ThumbnailImage(item, fit: BoxFit.cover),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularThumbnailWithAnimation(Item item) {
    double height = 90;
    double borderWidth = 2;
    return SizedBox(
      height: height,
      child: CircleAvatar(
        radius: height / 2,
        backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        child: Stack(
          children: [
            RotationTransition(
              // turns: CurveTween(curve: Curves.easeInToLinear).animate(_animationController),
              turns: Tween(begin: 0.0, end: 4.0).animate(_animationController),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.onSurfaceVariant,
                      Theme.of(context).colorScheme.surfaceVariant,
                    ],
                    stops: const [0, 1],
                  ),
                  borderRadius: BorderRadius.circular(45),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(borderWidth),
              child: ClipOval(
                child: SizedBox(
                  height: height - 2 * borderWidth,
                  width: height - 2 * borderWidth,
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.passthrough,
                    children: [
                      Container(color: Theme.of(context).colorScheme.surfaceVariant),
                      ThumbnailImage(item, fit: BoxFit.cover),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TopPicksModel model = context.watch<TopPicksModel>();
    Map<int, List<Media>> mediaByYear = model.content;
    if (mediaByYear.isEmpty) {
      return const TopPicksContainer(expand: false);
    }
    List<int> sortedYears = mediaByYear.keys.sorted((a, b) => a.compareTo(b));
    return TopPicksContainer(
      expand: true,
      child: _buildListView(
        mediaByYear.length,
        (context, pos) {
          int year = sortedYears.elementAt(pos);
          List<Media> media = mediaByYear[year]!;
          return Column(
            key: ValueKey(media.first.id),
            children: [
              GestureDetector(
                onTap: () {
                  List<int> sortedDates = media.map((it) => it.metadata.date.toInt()).sorted((a, b) => a.compareTo(b));
                  DateTime first = _dateFromUnixTimestamp(sortedDates.first);
                  DateTime last = _dateFromUnixTimestamp(sortedDates.last);
                  String name;
                  if (first == last) {
                    name = format.format(first);
                  } else {
                    name = "${format.format(first)} – ${format.format(last)}";
                  }
                  _openDirectory(
                    context,
                    Directory(
                      id: -1,
                      name: name,
                      relativeApiPath: "",
                      relativeThumbnailPath: "",
                      directories: [],
                      media: media,
                      metadata: DirectoryMetadata(lastModified: 0, mediaCount: media.length),
                    ),
                  );
                },
                child: model.isLoading ? _buildCircularThumbnailWithAnimation(media.first) : _buildCircularThumbnail(media.first),
              ),
              const SizedBox(height: 7),
              Text(
                year.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  fontSize: 15,
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
