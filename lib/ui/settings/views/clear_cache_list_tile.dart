import 'package:flutter/material.dart';
import 'package:pigallery2_android/util/extensions.dart';

class ClearCacheListTile extends StatefulWidget {
  final String title;
  final Future<int> Function() cacheSize;
  final int Function() memorySize;
  final Future<void> Function() onClear;

  const ClearCacheListTile({
    super.key,
    required this.title,
    required this.cacheSize,
    required this.memorySize,
    required this.onClear,
  });

  @override
  State<ClearCacheListTile> createState() => _ClearCacheListTileState();
}

class _ClearCacheListTileState extends State<ClearCacheListTile> {
  late Future<int> cacheSize;

  @override
  void initState() {
    super.initState();
    cacheSize = widget.cacheSize();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        await widget.onClear();
        setState(() {
          cacheSize = widget.cacheSize();
        });
      },
      title: Text(widget.title),
      trailing: Icon(Icons.delete),
      subtitle: FutureBuilder(
        future: cacheSize,
        builder: (context, snapshot) {
          int? data = snapshot.data;
          if (data == null) return Text("");
          return Text("Disk: ${data.toHumanReadableFileSize()}\nMemory: ${widget.memorySize().toHumanReadableFileSize()}");
        },
      ),
    );
  }
}