import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../models/image_element_model.dart';

class ImageElement extends HookWidget {
  const ImageElement({
    super.key,
    required this.imageElement,
  });

  final ImageElementModel imageElement;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageElement.url,
      fit: BoxFit.contain,
      width: imageElement.bounds.width,
      height: imageElement.bounds.height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Text('Failed to load image');
      },
    );
  }
}
