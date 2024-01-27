import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:provider/provider.dart';

class BadCertificateSelection extends StatefulWidget {
  const BadCertificateSelection({super.key});

  @override
  State<BadCertificateSelection> createState() => _BadCertificateSelectionState();
}

class _BadCertificateSelectionState extends State<BadCertificateSelection> {
  bool allowBadCertificate = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      allowBadCertificate = context.read<SharedPrefsStorage>().get(StorageKey.allowBadCertificates);
    });
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor = Theme.of(context).colorScheme.onSecondaryContainer;
    return InkWell(
      onTap: () {
        setState(() {
          allowBadCertificate = !allowBadCertificate;
          context.read<SharedPrefsStorage>().set(StorageKey.allowBadCertificates, allowBadCertificate);
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 15, 0),
              child: Stack(
                children: [
                  allowBadCertificate ? Icon(Icons.check_circle_rounded, color: iconColor) : Icon(Icons.check_circle_outline_rounded, color: iconColor),
                ],
              ),
            ),
            const Text("Allow Bad Certificates (Requires Restart)"),
          ],
        ),
      ),
    );
  }
}
