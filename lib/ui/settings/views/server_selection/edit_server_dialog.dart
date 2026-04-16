import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/storage/models/server_settings.dart';
import 'package:pigallery2_android/ui/settings/viewmodels/server_model.dart';
import 'package:provider/provider.dart';

class EditServerDialog extends StatefulWidget {
  final Server server;

  const EditServerDialog({super.key, required this.server});

  @override
  State<EditServerDialog> createState() => _EditServerDialogState();
}

class _EditServerDialogState extends State<EditServerDialog> {
  late final TextEditingController _thumbnailController;
  late final TextEditingController _videoController;
  late final TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    _thumbnailController = TextEditingController(text: widget.server.apiSettings.thumbnailPath);
    _videoController = TextEditingController(text: widget.server.apiSettings.videoPath);
    _imageController = TextEditingController(text: widget.server.apiSettings.imagePath);
  }

  @override
  void dispose() {
    _thumbnailController.dispose();
    _videoController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<ServerModel>().updateApiSettings(
      widget.server.id,
      widget.server.apiSettings.copyWith(
        thumbnailPath: _thumbnailController.text,
        videoPath: _videoController.text,
        imagePath: _imageController.text,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Remove Server"),
        content: Text("Remove ${widget.server.url}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              context.read<ServerModel>().deleteServer(widget.server.id);
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondaryStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Edit Server"),
          const SizedBox(height: 2),
          Text(widget.server.url, style: secondaryStyle),
          if (widget.server.username != null) Text(widget.server.username!, style: secondaryStyle),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              "Compatibility",
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).textButtonTheme.style?.foregroundColor?.resolve({})
                        ?? Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _thumbnailController,
              decoration: const InputDecoration(
                labelText: "Thumbnail path",
                helperText: "Default: /320 · Older: /thumbnail/240 · Empty for full resolution",
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _videoController,
              decoration: const InputDecoration(
                labelText: "Video path",
                helperText: "Use if converted videos should be played instead of the original files.\nExample: /bestfit",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: "Image path",
                helperText: "Use if converted images should be shown instead of full resolution images.\n/<size> where <size> is the size configured in the photo converting job",
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _confirmDelete,
          child: const Text("Remove"),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: _save,
              child: const Text("Save"),
            ),
          ],
        ),
      ],
    );
  }
}
