import 'package:flutter/material.dart';
import 'package:pigallery2_android/ui/settings/views/edit_text_dialog.dart';

class EditTextListTile extends StatelessWidget {
  final String title;
  final String description;
  final String initialValue;
  final void Function(String) onSave;

  const EditTextListTile({
    super.key,
    required this.title,
    required this.description,
    required this.initialValue,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) {
            return EditTextDialog(
              title: title,
              description: description,
              initialValue: initialValue,
              onSave: onSave,
            );
          },
        );
      },
      title: Text(title),
      subtitle: Text(initialValue),
      trailing: Icon(Icons.edit),
    );
  }
}