import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const ImagePreviewScreen({super.key, required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const HeroIcon(HeroIcons.xMark, color: Colors.white),
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Center(child: Text('Failed to load image')),
            ),
          ),
        ),
      ),
    );
  }
}
