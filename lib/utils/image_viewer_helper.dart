import 'package:flutter/material.dart';
import '../widgets/fullscreen_image_viewer.dart';

class ImageViewerHelper {

  static void abrir(
    BuildContext context, {
    required List<String> images,
    required int initialIndex,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
    
  }
}
