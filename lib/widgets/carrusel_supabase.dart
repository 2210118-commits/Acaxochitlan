import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../supabase/supabase_client.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_view/photo_view.dart';
import '../../main.dart'; // 👈 donde está tu routeObserver
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:io';
import '../cache/custom_cache_manager.dart';
import '../utils/media_optimizer.dart';

class CarruselSupabase extends StatefulWidget {
  final bool esAdmin;
  final bool pausarVideo;

  const CarruselSupabase({
    super.key,
    required this.esAdmin,
    required this.pausarVideo,
  });

  @override
  State<CarruselSupabase> createState() => _CarruselSupabaseState();
}

class _CarruselSupabaseState extends State<CarruselSupabase> {
  int _currentIndex = 0;
  late Future<List<Map<String, dynamic>>> _imagenesFuture;

  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _imagenesFuture = obtenerImagenes();
  }

  void _recargarCarrusel() {
    setState(() {
      _imagenesFuture = obtenerImagenes();
    });
  }

  Future<List<Map<String, dynamic>>> obtenerImagenes() async {
    try {
      final res = await SupabaseConfig.client
          .from('carrusel_imagenes')
          .select('id, image_url, es_video')
          .eq('activo', true)
          .order('created_at', ascending: false);

      print("🔥 DATOS CARRUSEL: $res");

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint("❌ ERROR CARRUSEL: $e");
      return [];
    }
  }

  Future<void> eliminarImagen(String imageUrl, String idImagen) async {
    try {
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      await SupabaseConfig.client.storage.from('carrusel').remove([fileName]);

      await SupabaseConfig.client
          .from('carrusel_imagenes')
          .delete()
          .eq('id', idImagen);

      _recargarCarrusel();
    } catch (e) {
      debugPrint("❌ ERROR ELIMINAR: $e");
    }
  }

  // 🖼️ FULLSCREEN IMAGEN
  void _verImagenFullscreen(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PhotoView(
                imageProvider: CachedNetworkImageProvider(imageUrl),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _imagenesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 250,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox(
            height: 250,
            child: Center(
              child: Text("Error cargando carrusel"),
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text('No hay imágenes en el carrusel'),
            ),
          );
        }

        // 🔥 Evita crash si borras elementos o cambia cantidad
        if (_currentIndex >= items.length) {
          _currentIndex = 0;
        }

        return Column(
          children: [
            CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                height: 250,
                autoPlay: !(items[_currentIndex]['es_video'] == true),
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: items.map((img) {
                final imageUrlOriginal = img['image_url'];

                final imageUrl = MediaOptimizer.carrusel(imageUrlOriginal);
                final idImagen = img['id'];
                final esVideo = img['es_video'] == true;

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: esVideo
                          ? VideoCarruselItem(
                              videoUrl: imageUrl,
                              isActive: items.indexOf(img) == _currentIndex,
                              pausarVideo: widget.pausarVideo,
                              onVideoFinished: () {
                                _carouselController.nextPage(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOut,
                                );
                              },
                            )
                          : GestureDetector(
                              onTap: () => _verImagenFullscreen(
                                context,
                                imageUrl,
                              ),
                              child: CachedNetworkImage(
                                cacheManager: CustomCacheManager.instance,
                                imageUrl: imageUrl,
                                height: 230,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                fadeInDuration:
                                    const Duration(milliseconds: 700),
                                fadeOutDuration:
                                    const Duration(milliseconds: 300),
                                placeholder: (context, url) => Container(
                                  color: Colors.black12,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.broken_image,
                                ),
                                memCacheWidth: 700,
                                memCacheHeight: 350,
                              ),
                            ),
                    ),

                    // ❌ BOTÓN ELIMINAR (SOLO ADMIN)
                    if (widget.esAdmin)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 28,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Eliminar archivo'),
                                content: const Text(
                                  '¿Deseas eliminar este archivo permanentemente?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await eliminarImagen(
                                imageUrl,
                                idImagen,
                              );
                            }
                          },
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: items.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _carouselController.animateToPage(
                    entry.key,
                  ),
                  child: Container(
                    width: _currentIndex == entry.key ? 10 : 8,
                    height: _currentIndex == entry.key ? 10 : 8,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? Colors.blueAccent
                          : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

/// 🎥 WIDGET VIDEO (AISLADO – NO TOCA NADA MÁS)
class VideoCarruselItem extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final bool pausarVideo;
  final VoidCallback? onVideoFinished;

  const VideoCarruselItem({
    super.key,
    required this.videoUrl,
    required this.isActive,
    required this.pausarVideo,
    this.onVideoFinished,
  });

  @override
  State<VideoCarruselItem> createState() => _VideoCarruselItemState();
}

class _VideoCarruselItemState extends State<VideoCarruselItem>
    with WidgetsBindingObserver, RouteAware {
  bool _enPantalla = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didUpdateWidget(covariant VideoCarruselItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_controller == null || !_controller!.value.isInitialized) return;

    final puedeReproducir =
        _enPantalla && widget.isActive && !widget.pausarVideo;

    if (puedeReproducir) {
      _controller!.play();
    } else {
      _controller!.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // 🔥 Cuando sales de la pantalla
      _controller!.pause();
    }

    if (state == AppLifecycleState.resumed) {
      // 🔥 cuando regreses a la app se queda pausado
      _controller?.pause();
    }
  }

  VideoPlayerController? _controller;

  bool _videoTerminado = false;

  Future<void> _initVideo() async {
    if (!mounted) return;

    try {
      if (Platform.isWindows) {
        // 🔥 WINDOWS: usar stream directo (sin cache)
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
          ),
        );
      } else {
        // ✅ ANDROID / iOS: usar cache como ya tienes
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
          ),
        );
      }

      await _controller!.initialize();

      _controller!
        ..setLooping(false)
        ..setVolume(1.0);

      _controller!.addListener(() {
        final pos = _controller!.value.position;
        final dur = _controller!.value.duration;

        if (!_videoTerminado &&
            dur != Duration.zero &&
            pos >= dur &&
            !_controller!.value.isPlaying) {
          _videoTerminado = true;
          widget.onVideoFinished?.call();
        }
      });

      if (_enPantalla && widget.isActive && !widget.pausarVideo) {
        _controller!.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("❌ Error video Windows: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 👈 AGREGA ESTO
    _initVideo();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this); // 👈 IMPORTANTE
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    _enPantalla = false;
    _controller?.pause();
  }

  @override
  void didPopNext() {
    _enPantalla = true;

    if (widget.isActive && !widget.pausarVideo) {
      _controller?.play();
    }
  }

  void _abrirVideoFullscreen() {
    _controller?.pause(); // 🔥 pausa antes de abrir

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoFullscreenPage(videoUrl: widget.videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0.6;

        final puedeReproducir =
            visible && _enPantalla && widget.isActive && !widget.pausarVideo;

        if (puedeReproducir) {
          _controller?.play();
        } else {
          _controller?.pause();
        }
      },
      child: GestureDetector(
        onTap: _abrirVideoFullscreen,
        child: SizedBox(
          height: 230,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoFullscreenPage extends StatefulWidget {
  final String videoUrl;

  const VideoFullscreenPage({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<VideoFullscreenPage> {
  late VideoPlayerController _controller;
  bool mostrandoControles = true;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    )..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      setState(() {}); // actualiza el slider
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => mostrandoControles = !mostrandoControles);
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            /// VIDEO
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            /// CONTROLES
            if (mostrandoControles && _controller.value.isInitialized)
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
                    /// SLIDER CON BOLITA
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: Colors.redAccent,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        min: 0,
                        max: _controller.value.duration.inMilliseconds
                            .toDouble(),
                        value: _controller.value.position.inMilliseconds
                            .clamp(
                              0,
                              _controller.value.duration.inMilliseconds,
                            )
                            .toDouble(),
                        onChanged: (value) {
                          _controller.seekTo(
                            Duration(milliseconds: value.toInt()),
                          );
                        },
                      ),
                    ),

                    /// CONTROLES INFERIORES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// PLAY / PAUSE
                        IconButton(
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: togglePlay,
                        ),

                        /// TIEMPO
                        Text(
                          '${_formatDuration(_controller.value.position)} / '
                          '${_formatDuration(_controller.value.duration)}',
                          style: const TextStyle(color: Colors.white),
                        ),

                        /// CERRAR
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
