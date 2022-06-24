import 'package:flutter/material.dart';

class ErrorImage extends StatelessWidget {
  const ErrorImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xffa1a1a1),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey[400],
          size: 40.0,
        ),
      ),
    );
  }
}
