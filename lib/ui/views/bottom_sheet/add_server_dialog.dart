import 'package:flutter/material.dart';
import 'package:pigallery2_android/core/viewmodels/server_model.dart';
import 'package:provider/provider.dart';

class AddServerDialog extends StatefulWidget {
  const AddServerDialog({Key? key}) : super(key: key);

  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final addServerController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  FocusNode addServerFocus = FocusNode();
  final String hintText = "https://pigallery2.herokuapp.com";

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

  InputDecoration buildInputDecorationUrl(BuildContext context) {
    ServerModel model = Provider.of<ServerModel>(context, listen: true);
    return model.testFailedUrl
        ? const InputDecoration(
            errorText: "Can't connect to server",
          )
        : (model.testSuccessUrl
            ? const InputDecoration(
                errorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                focusedErrorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                errorStyle: TextStyle(color: Colors.green),
                errorText: "Valid server",
              )
            : InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 14),
              ));
  }

  InputDecoration buildInputDecorationAuth(BuildContext context, InputDecoration defaultDecoration) {
    ServerModel model = Provider.of<ServerModel>(context, listen: true);
    return model.testFailedAuth
        ? const InputDecoration(
            errorText: "Authentication failed",
          )
        : (model.testSuccessAuth
            ? const InputDecoration(
                errorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                focusedErrorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                errorStyle: TextStyle(color: Colors.green),
                errorText: "Authentication successful",
              )
            : defaultDecoration);
  }

  Widget buildServerUrlWidget(BuildContext context) {
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
          decoration: buildInputDecorationUrl(
            context,
          ),
          onSubmitted: (url) => testConnection(context),
          onChanged: (_) => Provider.of<ServerModel>(context, listen: false).urlChanged(),
        ),
      ),
      const SizedBox(
        width: 10,
      ),
      MaterialButton(
        color: Colors.white.withAlpha((0.15 * 255).toInt()),
        onPressed: () {
          if (Provider.of<ServerModel>(context, listen: false).testSuccessUrl && Provider.of<ServerModel>(context, listen: false).testSuccessAuth) {
            Navigator.pop(context, [addServerController.text.isEmpty ? null : addServerController.text, usernameController.text.isEmpty ? null : usernameController.text, passwordController.text.isEmpty ? null : passwordController.text]);
          } else {
            testConnection(context);
          }
        },
        height: 40,
        child: Text(Provider.of<ServerModel>(context).testSuccessAuth && Provider.of<ServerModel>(context).testSuccessUrl ? 'Add' : 'Test'),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerModel>(
      builder: ((context, value, child) => AlertDialog(
            insetPadding: const EdgeInsets.all(10),
            title: const Text('Add a Server'),
            scrollable: true,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Column(
                children: [
                  buildServerUrlWidget(context),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: usernameController,
                    onChanged: (_) => Provider.of<ServerModel>(context, listen: false).credentialsChanged(),
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
                    onChanged: (_) => Provider.of<ServerModel>(context, listen: false).credentialsChanged(),
                    decoration: buildInputDecorationAuth(context, const InputDecoration(labelText: "Password (optional)")),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
