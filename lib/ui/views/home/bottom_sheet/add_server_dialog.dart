import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/util/extensions.dart';
import 'package:pigallery2_android/core/viewmodels/server_model.dart';
import 'package:provider/provider.dart';

class AddServerDialog extends StatefulWidget {
  const AddServerDialog({super.key});

  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final addServerController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  FocusNode addServerFocus = FocusNode();
  final String hintText = "https://pigallery2.example.com";

  @override
  void dispose() {
    addServerFocus.dispose();
    addServerController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void testConnection(BuildContext context) {
    Provider.of<ServerModel>(context, listen: false).testConnection(
      addServerController.text,
      usernameController.text.isEmpty ? null : usernameController.text,
      passwordController.text.isEmpty ? null : passwordController.text,
    );
  }

  InputDecoration buildSuccessInputDecoration(BuildContext context, String successText) {
    Color successColor = Colors.green.harmonizeWith(Theme.of(context).colorScheme.primary);
    return InputDecoration(
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: successColor),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: successColor),
      ),
      errorStyle: TextStyle(color: successColor),
      errorText: successText,
    );
  }

  InputDecoration buildInputDecorationUrl(BuildContext context) {
    ServerModel model = Provider.of<ServerModel>(context, listen: false);
    return model.testFailedUrl
        ? const InputDecoration(errorText: "Can't connect to server")
        : (model.testSuccessUrl
            ? buildSuccessInputDecoration(context, "Valid server")
            : InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 14),
              ));
  }

  InputDecoration buildInputDecorationAuth(BuildContext context, InputDecoration defaultDecoration) {
    ServerModel model = Provider.of<ServerModel>(context, listen: false);
    return model.testFailedAuth ? const InputDecoration(errorText: "Authentication failed") : (model.testSuccessAuth ? buildSuccessInputDecoration(context, "Authentication successful") : defaultDecoration);
  }

  Widget buildServerUrlWidget(BuildContext context) {
    ServerModel serverModel = Provider.of<ServerModel>(context, listen: false);
    return Row(children: [
      Flexible(
        child: TextField(
          focusNode: addServerFocus,
          onTap: () {
            if (addServerFocus.hasFocus && addServerController.text.isEmpty) {
              addServerController.text = hintText;
            }
          },
          controller: addServerController,
          decoration: buildInputDecorationUrl(context),
          onSubmitted: (url) => testConnection(context),
          onChanged: (_) => serverModel.urlChanged(),
        ),
      ),
      const SizedBox(width: 10),
      MaterialButton(
        color: Theme.of(context).colorScheme.secondaryContainer,
        onPressed: () async {
          if (serverModel.testSuccessUrl && serverModel.testSuccessAuth) {
            await serverModel.addServer(addServerController.text, usernameController.text.ifEmpty(null), passwordController.text.ifEmpty(null));
            if (mounted) Navigator.pop(context);
          } else {
            testConnection(context);
          }
        },
        height: 40,
        child: Text(serverModel.testSuccessAuth && serverModel.testSuccessUrl ? 'Add' : 'Test'),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerModel>(
      builder: (context, ServerModel serverModel, child) => AlertDialog(
            insetPadding: const EdgeInsets.all(10),
            title: const Text('Add a Server'),
            scrollable: true,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Column(
                children: [
                  buildServerUrlWidget(context),
                  const SizedBox(height: 20),
                  TextField(
                    controller: usernameController,
                    onChanged: (_) => serverModel.credentialsChanged(),
                    decoration: buildInputDecorationAuth(
                      context,
                      const InputDecoration(
                        labelText: "Username (optional)",
                      ),
                    ),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    onChanged: (_) => serverModel.credentialsChanged(),
                    decoration: buildInputDecorationAuth(context, const InputDecoration(labelText: "Password (optional)")),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
