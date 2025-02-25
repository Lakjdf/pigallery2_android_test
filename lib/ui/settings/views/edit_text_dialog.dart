import 'package:flutter/material.dart';

class EditTextDialog extends StatefulWidget {
  final String title;
  final String description;
  final void Function(String) onSave;
  final String initialValue;
  final TextEditingController controller;

  EditTextDialog({
    super.key,
    required this.title,
    required this.description,
    required this.initialValue,
    required this.onSave,
  }) : controller = TextEditingController(text: initialValue);

  @override
  State<EditTextDialog> createState() => _EditTextDialogState();
}

class _EditTextDialogState extends State<EditTextDialog> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: widget.initialValue,
            ),
          ),
        ],
      ),
      actions: [
        MaterialButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        MaterialButton(
          onPressed: () {
            widget.onSave(widget.controller.text);
            Navigator.of(context).pop();
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}