import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/models/server_settings.dart';
import 'package:pigallery2_android/ui/settings/viewmodels/add_server_model.dart';
import 'package:pigallery2_android/ui/settings/viewmodels/server_model.dart';
import 'package:pigallery2_android/ui/settings/views/server_selection/add_server_dialog.dart';
import 'package:pigallery2_android/ui/settings/views/server_selection/edit_server_dialog.dart';
import 'package:pigallery2_android/ui/shared/widgets/selectable_card.dart';
import 'package:provider/provider.dart';

class ServerSelection extends StatelessWidget {
  const ServerSelection({super.key});

  void _showEditDialog(BuildContext context, Server server) {
    showDialog(
      context: context,
      builder: (_) => EditServerDialog(server: server),
    );
  }

  void addServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        Provider.of<AddServerModel>(context, listen: false).reset();
        return const AddServerDialog();
      },
    );
  }

  List<Widget> buildListItems(BuildContext context, String? selectedServerId) {
    return context.select<ServerModel, Iterable<Server>>((it) => it.servers).map(
      (server) {
        return SelectableCard(
          isSelected: server.id == selectedServerId,
          onSelected: () => context.read<ServerModel>().selectServer(server.id),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(server.url),
              Text(
                server.username ?? "No credentials",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          trailing: IconButton(
            onPressed: () => _showEditDialog(context, server),
            icon: const Icon(Icons.tune),
          ),
        );
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...buildListItems(context, context.select<ServerModel, String?>((it) => it.serverId)),
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
      ],
    );
  }
}
