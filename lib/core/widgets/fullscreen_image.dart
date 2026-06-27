import 'package:flutter/material.dart';

class FullscreenImage extends StatelessWidget {
  const FullscreenImage({super.key, required this.image});

  final ImageProvider image;

  static Future<void> show(BuildContext context, ImageProvider image) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullscreenImage(image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image(image: image, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
