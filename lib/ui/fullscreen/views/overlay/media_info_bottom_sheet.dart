import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/ui/server_settings/views/bottom_sheet_handle.dart';
import 'package:pigallery2_android/util/extensions.dart';

class MediaInfoBottomSheet extends StatelessWidget {
  final Media item;

  const MediaInfoBottomSheet(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(item.metadata.date.toInt() * 1000);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 6, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetHandle(),
          Column(
            spacing: 6,
            children: [
              ListTile(
                leading: Icon(Icons.image_outlined),
                title: Text("/${Uri.decodeComponent(item.relativeApiPath)}"),
                subtitle: Text(item.metadata.size.toHumanReadableFileSize()),
              ),
              ListTile(
                leading: Icon(Icons.date_range),
                title: Text(DateFormat.yMMMMd().format(dateTime)),
                subtitle: Text(DateFormat("EEEE, HH:mm:ss").format(dateTime)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
