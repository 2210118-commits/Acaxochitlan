import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState
    extends State<FullScreenImageViewer> {

  late PageController _pageController;
  late int currentIndex;

  /// 🔥 Precarga actual, siguiente y anterior
  void _precacheImagenes(int indexActual) {

    // Actual
    precacheImage(
      NetworkImage(widget.images[indexActual]),
      context,
    );

    // Siguiente
    if (indexActual + 1 < widget.images.length) {
      precacheImage(
        NetworkImage(widget.images[indexActual + 1]),
        context,
      );
    }

    // Anterior
    if (indexActual - 1 >= 0) {
      precacheImage(
        NetworkImage(widget.images[indexActual - 1]),
        context,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex;

    _pageController =
        PageController(initialPage: widget.initialIndex);

    /// 🔥 Precargar después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImagenes(widget.initialIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// 🔁 DESLIZAR ENTRE IMÁGENES
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });

              _precacheImagenes(index);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          /// 🔢 INDICADOR
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "${currentIndex + 1} / ${widget.images.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          /// ❌ BOTÓN CERRAR
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
