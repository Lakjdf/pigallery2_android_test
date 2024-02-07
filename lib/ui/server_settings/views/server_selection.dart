import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/server_settings/viewmodels/server_model.dart';
import 'package:pigallery2_android/ui/server_settings/views/add_server_dialog.dart';
import 'package:pigallery2_android/ui/shared/widgets/selectable_card.dart';
import 'package:provider/provider.dart';

class ServerSelection extends StatelessWidget {
  const ServerSelection({super.key});

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
      builder: (_) {
        Provider.of<ServerModel>(context, listen: false).reset();
        return const AddServerDialog();
      },
    );
  }

  List<Widget> buildListItems(BuildContext context, String? selectedServer) {
    return context.select<ServerModel, List<String>>((it) => it.serverUrls).map(
      (url) {
        return SelectableCard(
          isSelected: url == selectedServer,
          onSelected: () => context.read<ServerModel>().selectServer(url),
          title: Text(url),
          trailing: IconButton(
            onPressed: () => askDeleteServer(context, url),
            icon: const Icon(Icons.delete),
          ),
        );
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...buildListItems(context, context.select<ServerModel, String?>((it) => it.serverUrl)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 35,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: MaterialButton(
              color: Theme.of(context).colorScheme.secondaryContainer,
              onPressed: () => addServerDialog(context),
              child: Text(
                'Add Server',
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
