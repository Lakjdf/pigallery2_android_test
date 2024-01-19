import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadCertificateSelection extends StatefulWidget {
  const BadCertificateSelection({super.key});

  @override
  State<BadCertificateSelection> createState() => _BadCertificateSelectionState();
}

class _BadCertificateSelectionState extends State<BadCertificateSelection> {
  bool allowBadCertificate = false;
  final String prefsKey = "allowBadCertificate";

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) => {
          setState(() {
            allowBadCertificate = prefs.getBool(prefsKey) ?? false;
          })
        });
  }

  Future<void> storeValue(bool val) async {
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(prefsKey, val));
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor = Theme.of(context).colorScheme.onSecondaryContainer;
    return InkWell(
      onTap: () {
        setState(() {
          allowBadCertificate = !allowBadCertificate;
          storeValue(allowBadCertificate);
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
