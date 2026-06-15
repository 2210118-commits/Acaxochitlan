import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import '../../supabase/supabase_client.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:acaxochi/widgets/texto_expandable.dart';
import '../widgets/bottom_nav.dart';




class ActividadesPage extends StatelessWidget {
  const ActividadesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = SupabaseConfig.client
        .from('publicaciones')
        .stream(primaryKey: ['id'])
        .order('fecha_creacion', ascending: false);

    return Scaffold(
      bottomNavigationBar: const BottomNav(
  currentIndex: 0,
),
      appBar: AppBar(
        title: const Text('Actividades'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar publicaciones'),
            );
          }

          final publicaciones = snapshot.data ?? [];

          if (publicaciones.isEmpty) {
            return const Center(
              child: Text('No hay actividades disponibles'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(5),
            itemCount: publicaciones.length,
           ///////////////////////////MANTIENE LOS ITEMS VIVOS
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            cacheExtent: 400,
            itemBuilder: (context, index) {
              final pub = publicaciones[index];

              final List<String> imagenes =
                  (pub['imagenes'] as List?)?.cast<String>() ?? [];

              final List<String> videos =
                  (pub['videos'] as List?)?.cast<String>() ?? [];
              
              final media = [
               ...imagenes.map((e) => {'tipo': 'imagen', 'url': e}),
               ...videos.map((e) => {'tipo': 'video', 'url': e}),
              ];

              return KeepAliveWrapper(
              child: Card(
                margin: const EdgeInsets.only(bottom: 1),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pub['titulo']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      TextoExpandable(
  texto: pub['descripcion'] ?? '',
),



                      const SizedBox(height: 5),

                      //  IMÁGENES ESTILO FACEBOOK
                      if (media.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 5),
    child: _MediaLayoutFacebook(media: media),
  ),
                      const SizedBox(height: 8),

                      
                    ],
                  ),
                ),
              ),
              );
            },
          );
        },
      ),
    );
  }
  
}
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({required this.child, super.key});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// IMAGENES COMO EN FACEBOOK
class _MediaLayoutFacebook extends StatelessWidget {
  final List<Map<String, String>> media;

  const _MediaLayoutFacebook({required this.media});

  @override
  Widget build(BuildContext context) {
    final total = media.length;
    final altura = MediaQuery.of(context).size.height * 0.50;

    if (total == 1) {
      return SizedBox(
        height: altura,
        child: _mediaItem(context, media[0], 0),
      );
    }

    if (total == 2) {
      return SizedBox(
        height: altura,
        child: Row(
          children: [
            Expanded(child: _mediaItem(context, media[0], 0)),
            const SizedBox(width: 2),
            Expanded(child: _mediaItem(context, media[1], 1)),
          ],
        ),
      );
    }

    if (total == 3) {
      return SizedBox(
        height: altura,
        child: Column(
          children: [
            Expanded(child: _mediaItem(context, media[0], 0)),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _mediaItem(context, media[1], 1)),
                  const SizedBox(width: 2),
                  Expanded(child: _mediaItem(context, media[2], 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final restantes = total - 4;

    return SizedBox(
      height: altura,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _mediaItem(context, media[index], index),
              if (index == 3 && restantes > 0)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+$restantes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _mediaItem(
    BuildContext context, Map<String, String> item, int index) {
  final isVideo = item['tipo'] == 'video';

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MediaFullscreenPage(
            media: media,
            indexInicial: index,
          ),
        ),
      );
    },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          isVideo
              ? VideoItem(url: item['url']!)
              : Image.network(
  item['url']!,
  fit: BoxFit.cover,

  // CACHE
  cacheWidth: 600,
  filterQuality: FilterQuality.low,

  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  },
  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
),


          if (isVideo)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 60,
                color: Colors.white,
              ),
            ),
        ],
      ),
    ),
  );
}
}
class VideoItem extends StatefulWidget {
  final String url;
  const VideoItem({required this.url, super.key});

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final thumb = await VideoThumbnail.thumbnailData(
      video: widget.url,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 600,
      quality: 75,
    );

    if (mounted) {
      setState(() {
        _thumbnail = thumb;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_thumbnail != null)
            Image.memory(
              _thumbnail!,
              fit: BoxFit.cover,
            )
          else
            Container(color: Colors.black12),

          const Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 60,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class MediaFullscreenPage extends StatefulWidget {
  final List<Map<String, String>> media;
  final int indexInicial;

  const MediaFullscreenPage({
    required this.media,
    required this.indexInicial,
    super.key,
  });

  @override
  State<MediaFullscreenPage> createState() => _MediaFullscreenPageState();
}

class _MediaFullscreenPageState extends State<MediaFullscreenPage> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  bool mostrandoControles = true;
  
  @override
void initState() {
  super.initState();
  _pageController = PageController(initialPage: widget.indexInicial);
  _initIfVideo(widget.indexInicial);
}


  Future<void> _initIfVideo(int index) async {
    final item = widget.media[index];

    _videoController?.dispose();
    _videoController = null;

    if (item['tipo'] != 'video') {
      setState(() {});
      return;
    }

    final file =
        await DefaultCacheManager().getSingleFile(item['url']!);

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    controller.play();
    controller.setLooping(true);

    controller.addListener(() {
      if (mounted) setState(() {});
    });

    if (!mounted) return;

    setState(() {
      _videoController = controller;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void togglePlay() {
    if (_videoController == null) return;

    setState(() {
      _videoController!.value.isPlaying
          ? _videoController!.pause()
          : _videoController!.play();
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => mostrandoControles = !mostrandoControles);
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.media.length,
          onPageChanged: (index) {
  _initIfVideo(index);
},
          itemBuilder: (context, index) {
            final item = widget.media[index];
            final isVideo = item['tipo'] == 'video';

            if (!isVideo) {
              return Center(
                child: InteractiveViewer(
                  child: Image.network(
  item['url']!,
  fit: BoxFit.contain,
  cacheWidth: 1080,
  filterQuality: FilterQuality.low,
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  },
  errorBuilder: (_, __, ___) => const Icon(
    Icons.broken_image,
    color: Colors.white,
    size: 60,
  ),
),


                ),
              );
            }

            if (_videoController == null ||
                !_videoController!.value.isInitialized) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final duration = _videoController!.value.duration;
            final position = _videoController!.value.position;

            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                /// VIDEO
                Center(
                  child: AspectRatio(
                    aspectRatio:
                        _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),

                /// CONTROLES
                if (mostrandoControles)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// SLIDER
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape:
                                const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape:
                                const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: Colors.redAccent,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            min: 0,
                            max: duration.inMilliseconds.toDouble(),
                            value: position.inMilliseconds
                                .clamp(0,
                                    duration.inMilliseconds)
                                .toDouble(),
                            onChanged: (value) {
                              _videoController!.seekTo(
                                Duration(
                                  milliseconds: value.toInt(),
                                ),
                              );
                            },
                          ),
                        ),

                        /// CONTROLES INFERIORES
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: togglePlay,
                            ),
                            Text(
                              '${_formatDuration(position)} / '
                              '${_formatDuration(duration)}',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
