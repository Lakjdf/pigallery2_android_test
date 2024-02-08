import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/metadata.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/top_picks/viewmodels/top_picks_model.dart';
import 'package:pigallery2_android/ui/home/views/home_view.dart';
import 'package:pigallery2_android/ui/shared/widgets/thumbnail_image.dart';
import 'package:pigallery2_android/ui/top_picks/views/top_picks_image_wrapper.dart';
import 'package:provider/provider.dart';

class TopPicksInnerView extends StatelessWidget {
  final DateFormat format = DateFormat("dd/MM/yyyy");

  TopPicksInnerView({super.key});

  void _openDirectory(BuildContext context, Directory directory) {
    HomeModel model = Provider.of<HomeModel>(context, listen: false);
    model.topPicksSearch(directory);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: ((context) => HomeView(1)),
      ),
    ).then((value) {
      model.popStack();
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    });
  }

  DateTime _dateFromUnixTimestamp(int timestamp) {
    return DateUtils.dateOnly(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
  }

  void _handleTap(BuildContext context, List<Media> media) {
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

  Widget _buildEntry(BuildContext context, List<Media> media, int year) {
    return Column(
      key: ValueKey(media.first.id),
      children: [
        GestureDetector(
          onTap: () => _handleTap(context, media),
          child: TopPicksImageWrapper(ThumbnailImage(media.first, fit: BoxFit.cover)),
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
  }

  @override
  Widget build(BuildContext context) {
    Map<int, List<Media>> mediaByYear = context.select<TopPicksModel, Map<int, List<Media>>>((it) => it.content);
    List<int> sortedYears = mediaByYear.keys.sorted((a, b) => a.compareTo(b));
    return _buildListView(
      mediaByYear.length,
      (context, pos) {
        int year = sortedYears.elementAt(pos);
        List<Media> media = mediaByYear[year]!;
        return _buildEntry(context, media, year);
      },
    );
  }
}
