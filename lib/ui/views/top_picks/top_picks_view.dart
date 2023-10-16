import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pigallery2_android/core/models/models.dart';
import 'package:pigallery2_android/core/services/api.dart';
import 'package:pigallery2_android/core/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/views/home_view.dart';
import 'package:pigallery2_android/ui/widgets/thumbnail_image.dart';
import 'package:provider/provider.dart';

class TopPicksView extends StatefulWidget {
  const TopPicksView({super.key});

  @override
  State<TopPicksView> createState() => _TopPicksViewState();
}

class _TopPicksViewState extends State<TopPicksView> with TickerProviderStateMixin {
  // late final AnimationController _animationController;
  DateFormat format = DateFormat("dd/MM/yyyy");

  @override
  void initState() {
    super.initState();
    // _animationController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(seconds: 15),
    // )..repeat();
  }

  @override
  void dispose() {
    // _animationController.dispose();
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

  DateTime _dateFromUnixTimestamp(double timestamp) {
    return DateUtils.dateOnly(DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000));
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

  Widget _buildCircularThumbnail(String? thumbnailUrl) {
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
                  ThumbnailImage(thumbnailUrl, fit: BoxFit.cover),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildCircularThumbnailWithAnimation(String? thumbnailUrl) {
  //   double height = 90;
  //   double borderWidth = 2;
  //   return SizedBox(
  //     height: height,
  //     child: CircleAvatar(
  //       radius: height / 2,
  //       backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
  //       child: Stack(
  //         children: [
  //           RotationTransition(
  //             // turns: CurveTween(curve: Curves.easeInToLinear).animate(_animationController),
  //             turns: Tween(begin: 0.0, end: 4.0).animate(_animationController),
  //             child: Container(
  //               decoration: BoxDecoration(
  //                 gradient: LinearGradient(
  //                   colors: [
  //                     Theme.of(context).colorScheme.onSurfaceVariant,
  //                     Theme.of(context).colorScheme.surfaceVariant,
  //                   ],
  //                   stops: const [0, 1],
  //                 ),
  //                 borderRadius: BorderRadius.circular(45),
  //               ),
  //             ),
  //           ),
  //           Padding(
  //             padding: EdgeInsets.all(borderWidth),
  //             child: ClipOval(
  //               child: SizedBox(
  //                 height: height - 2 * borderWidth,
  //                 width: height - 2 * borderWidth,
  //                 child: Stack(
  //                   alignment: Alignment.center,
  //                   fit: StackFit.passthrough,
  //                   children: [
  //                     Container(color: Theme.of(context).colorScheme.surfaceVariant),
  //                     ThumbnailImage(thumbnailUrl, fit: BoxFit.cover),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    ApiService api = Provider.of<ApiService>(context, listen: false);
    return FutureBuilder(
        future: api.getTopPicks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || snapshot.data?.media.isEmpty == true) {
            return Container();
          }
          Map<DateTime, List<Media>> mediaByDate = groupBy(snapshot.data!.media, (obj) => _dateFromUnixTimestamp(obj.metadata.creationDate));
          mediaByDate.removeWhere((key, value) => key.year == DateTime.now().year);
          List<DateTime> sortedDateTimes = mediaByDate.keys.sorted();
          return SizedBox(
            height: 132,
            child: _buildListView(mediaByDate.length, (context, pos) {
              DateTime dateTime = sortedDateTimes.elementAt(pos);
              List<Media> media = mediaByDate[dateTime]!;
              String? thumbnailUrl = api.getThumbnailApiPath(media.first);
              return Column(
                children: [
                  GestureDetector(
                    onTap: () => _openDirectory(
                      context,
                      Directory(
                        id: -1,
                        name: format.format(dateTime),
                        path: "",
                        mediaCount: 0,
                        lastModified: 0,
                        directories: [],
                        cover: null,
                        media: media,
                        parentPath: "",
                      ),
                    ),
                    child: _buildCircularThumbnail(thumbnailUrl),
                  ),
                  const SizedBox(height: 7),
                  Text(format.format(dateTime)),
                ],
              );
            }),
          );
        });
  }
}
