import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isLocal;
  final double aspectRatio;
  final double borderRadius;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.isLocal = false,
    this.aspectRatio = 1, // por defecto cuadrado
    this.borderRadius = 1,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  Uint8List? _thumbnail;
  

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 500,
        quality: 75,
      );

      if (mounted) {
        setState(() {
          _thumbnail = uint8list;
        });
      }
    } catch (_) {}
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VideoFullscreenPage(
          videoUrl: widget.videoUrl,
          
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: GestureDetector(
        onTap: _openFullscreen,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _thumbnail != null
                  ? Image.memory(
                      _thumbnail!,
                      fit: BoxFit.cover,
                    )
                  : Container(color: Colors.black12),

              Container(
                color: Colors.black.withOpacity(0.25),
              ),

              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoFullscreenPage extends StatefulWidget {
  final String videoUrl;

  const _VideoFullscreenPage({
    required this.videoUrl,
  });

  @override
  State<_VideoFullscreenPage> createState() =>
      _VideoFullscreenPageState();
}

class _VideoFullscreenPageState
    extends State<_VideoFullscreenPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
  _videoController = VideoPlayerController.networkUrl(
    Uri.parse(widget.videoUrl),
    videoPlayerOptions: VideoPlayerOptions(
      allowBackgroundPlayback: false,
    ),
  );

  await _videoController.initialize();

  _chewieController = ChewieController(
    videoPlayerController: _videoController,
    autoPlay: true,
    looping: false,
    allowFullScreen: true,
    allowMuting: true,
    showOptions: false,
    allowPlaybackSpeedChanging: false,
    showControls: true,
  );

  if (mounted) {
    setState(() {});
  }
}


  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: _chewieController == null
        ? const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 222, 201, 236),
            ),
          )
        : SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Chewie(
                    controller: _chewieController!,
                  ),
                ),

                // Botón para salir
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close, // cambia por Icons.arrow_back si prefieres flecha
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}
}
