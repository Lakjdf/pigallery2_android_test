import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/server_model.dart';
import 'package:pigallery2_android/ui/views/bottom_sheet/add_server_dialog.dart';
import 'package:provider/provider.dart';

class ServerSelection extends StatelessWidget {
  const ServerSelection({Key? key}) : super(key: key);

  askDeleteServer(BuildContext context, String url) {
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () => Navigator.pop(context),
    );
    Widget continueButton = TextButton(
      child: const Text("Remove"),
      onPressed: () {
        Provider.of<ServerModel>(context, listen: false).deleteServer(url);
        Navigator.pop(context);
      },
    );
    AlertDialog alert = AlertDialog(
      title: const Text("Remove Confirmation"),
      content: Text("Would you like to remove the server $url?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  addServerDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context2) {
          Provider.of<ServerModel>(context, listen: false).reset();
          return const AddServerDialog();
        }).then((returnValues) {
      if (returnValues != null) {
        Provider.of<ServerModel>(context, listen: false).addServer(returnValues[0], returnValues[1], returnValues[2]);
      }
    });
  }

  Widget _buildListItem(
    BuildContext context, {
    required String url,
    Widget? title,
    Widget? leading,
    Widget? trailing,
  }) {
    return Card(
      color: Colors.white.withAlpha((0.15 * 255).toInt()),
      shape: url == Provider.of<ServerModel>(context, listen: false).serverUrl
          ? RoundedRectangleBorder(
              side: const BorderSide(color: Colors.white, width: 1.6),
              borderRadius: BorderRadius.circular(10),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
      child: InkWell(
        onTap: () => Provider.of<ServerModel>(context, listen: false).selectServer(url),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (leading != null) leading,
              if (title != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: title,
                ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildListItems(BuildContext context) {
    List<Widget> listItems = [];
    for (String url in Provider.of<ServerModel>(context).serverUrls) {
      listItems.add(
        _buildListItem(
          context,
          url: url,
          title: Text(url),
          trailing: IconButton(
            onPressed: () => askDeleteServer(context, url),
            icon: const Icon(Icons.delete),
          ),
        ),
      );
    }
    return listItems;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: buildListItems(context) +
          [
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 35,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: MaterialButton(color: Colors.white.withAlpha((0.15 * 255).toInt()), onPressed: () => addServerDialog(context), child: const Text('Add Server')),
              ),
            ),
            const SizedBox(height: 24),
          ],
    );
  }
}
