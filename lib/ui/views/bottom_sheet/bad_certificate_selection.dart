import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadCertificateSelection extends StatefulWidget {
  const BadCertificateSelection({Key? key}) : super(key: key);

  @override
  State<BadCertificateSelection> createState() =>
      _BadCertificateSelectionState();
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
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(prefsKey, val));
  }

  @override
  Widget build(BuildContext context) {
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
                  allowBadCertificate
                      ? const Icon(Icons.check_circle_rounded)
                      : const Icon(Icons.check_circle_outline_rounded),
                ],
              ),
            ),
            const Text(
              "Allow Bad Certificates (Requires Restart)",
            ),
          ],
        ),
      ),
    );
  }
}
