import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'publicar_festividad_page.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:typed_data';
import 'package:acaxochi/widgets/texto_expandable.dart';
import 'detalle_festividad_page.dart';

class FestividadesPage extends StatelessWidget {
  const FestividadesPage({super.key});

  Future<bool> esAdmin() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return false;

    final data = await supabase
        .from('admin_profiles')
        .select('id')
        .eq('email', user.email!)
        .maybeSingle();

    return data != null;
  }
  Future<void> _eliminarPublicacion(
  BuildContext context,
  Map<String, dynamic> fest,
) async {

  final supabase = Supabase.instance.client;

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Eliminar publicación"),
      content: const Text(
          "¿Seguro que deseas eliminar esta festividad?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Eliminar"),
        ),
      ],
    ),
  );

  if (confirmar != true) return;

  try {

    /// 🔥 1️⃣ ELIMINAR ARCHIVOS DEL STORAGE
    final List<String> imagenes =
    (fest['imagenes'] as List?)
        ?.where((e) => e != null && e.toString().isNotEmpty)
        .map((e) => e.toString())
        .toList() ?? [];

final List<String> videos =
    (fest['videos'] as List?)
        ?.where((e) => e != null && e.toString().isNotEmpty)
        .map((e) => e.toString())
        .toList() ?? [];
    for (var url in [...imagenes, ...videos]) {

      final uri = Uri.parse(url);

      // 🔥 Obtener todo lo que está después del bucket
      final path = uri.pathSegments
          .skipWhile((segment) => segment != 'festividades')
          .skip(1)
          .join('/');

      if (path.isNotEmpty) {
        await supabase.storage
            .from('festividades')
            .remove([path]);
      }
    }

    /// 🔥 2️⃣ ELIMINAR REGISTRO (ESTO ACTUALIZA EL STREAM AUTOMÁTICAMENTE)
    await supabase
        .from('festividades')
        .delete()
        .eq('id', fest['id']);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Publicación eliminada correctamente"),
      ),
    );

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al eliminar: $e")),
    );
  }
}



  @override
  Widget build(BuildContext context) {

    final stream = Supabase.instance.client
        .from('festividades')
        .stream(primaryKey: ['id'])
        .order('fecha', ascending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Festividades')),

      // 🔥 BOTÓN SOLO PARA ADMIN
      floatingActionButton: FutureBuilder<bool>(
        future: esAdmin(),
        builder: (context, snapshot) {

          if (!snapshot.hasData || snapshot.data == false) {
            return const SizedBox.shrink();
          }
          

          return FloatingActionButton.extended(
            onPressed: () async {

  final resultado = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const PublicarFestividadPage(),
    ),
  );

  if (resultado == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Publicación creada correctamente"),
      ),
    );
  }
},

            icon: const Icon(Icons.celebration),
            label: const Text("Publicar"),
          );
        },
      ),

      body: FutureBuilder<bool>(
  future: esAdmin(),
  builder: (context, adminSnapshot) {

    final esAdminUser = adminSnapshot.data ?? false;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text("Error al cargar festividades"),
          );
        }

        final festividades = snapshot.data ?? [];

        if (festividades.isEmpty) {
          return const Center(
            child: Text("Aun no hay festividades"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(5),
          itemCount: festividades.length,
          itemBuilder: (context, index) {

            final fest = festividades[index];

            final List<String> imagenes =
    (fest['imagenes'] as List?)
        ?.where((e) => e != null && e.toString().isNotEmpty)
        .map((e) => e.toString())
        .toList() ?? [];

final List<String> videos =
    (fest['videos'] as List?)
        ?.where((e) => e != null && e.toString().isNotEmpty)
        .map((e) => e.toString())
        .toList() ?? [];

            final media = [
  ...imagenes
      .where((e) => e.isNotEmpty)
      .map((e) => {'tipo': 'imagen', 'url': e}),
  ...videos
      .where((e) => e.isNotEmpty)
      .map((e) => {'tipo': 'video', 'url': e}),
];

            return Card(
              margin: const EdgeInsets.only(bottom: 5),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // TITULO + MENU
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            fest['titulo']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        if (esAdminUser)
                          PopupMenuButton<String>(
  onSelected: (value) async {

    if (value == 'editar') {

      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicarFestividadPage(
            festividadEditar: fest,
          ),
        ),
      );

      if (resultado == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Festividad actualizada"),
          ),
        );
      }
    }

    if (value == 'eliminar') {
      _eliminarPublicacion(context, fest);
    }
  },

  itemBuilder: (context) => const [
    PopupMenuItem(
      value: 'editar',
      child: Row(
        children: [
          Icon(Icons.edit, size: 18),
          SizedBox(width: 8),
          Text("Editar"),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'eliminar',
      child: Row(
        children: [
          Icon(Icons.delete, size: 18, color: Colors.red),
          SizedBox(width: 8),
          Text("Eliminar"),
        ],
      ),
    ),
  ],
),

                      ],
                    ),

                    const SizedBox(height: 6),

                    /// DESCRIPCION
                    TextoExpandable(
                      texto: fest['descripcion']?.toString() ?? '',
                      maxLineas: 3,
                    ),
                    

                    const SizedBox(height: 8),

                    if (media.isNotEmpty)
                      _MediaLayoutFacebook(media: media),

                    const SizedBox(height: 8),

Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    child: const Text("Ver más"),
    onPressed: () {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleFestividadPage(
            festividad: fest,
          ),
        ),
      );

    },
  ),
),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  },
),

    );
  }
}


class _MediaLayoutFacebook extends StatelessWidget {
  final List<Map<String, dynamic>> media;

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

    final restantes = total - 4;

    return SizedBox(
      height: altura,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: total > 4 ? 4 : total,
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
    BuildContext context, Map<String, dynamic> item, int index) {

  final isVideo = item['tipo'] == 'video';
  final String url = item['url']?.toString() ?? '';

  if (url.isEmpty) {
    return const SizedBox();
  }

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
              ? VideoItem(url: url)
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image),
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
  if (widget.url.isEmpty) return;

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

//hacer reutilizable
class MediaFullscreenPage extends StatefulWidget {
  final List<Map<String, dynamic>> media;
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

    if (_videoController != null) {
      await _videoController!.pause();
      await _videoController!.dispose();
      _videoController = null;
    }

    if (item['tipo'] != 'video') {
      setState(() {});
      return;
    }

    final String url = item['url']?.toString() ?? '';
    if (url.isEmpty) return;

    final file = await DefaultCacheManager().getSingleFile(url);

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
            final String url = item['url']?.toString() ?? '';

            /// 🔥 VALIDACIÓN CLAVE (EVITA EL ERROR)
            if (url.isEmpty) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 60,
                ),
              );
            }

            /// 🔥 IMAGEN
            if (!isVideo) {
              return Center(
                child: InteractiveViewer(
                  child: Image.network(
                    url, // 🔥 AQUÍ estaba tu error (faltaba esto)
                    fit: BoxFit.contain,
                    cacheWidth: 1080,
                    filterQuality: FilterQuality.low,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
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

            /// 🔥 VIDEO
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
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),

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
                                .clamp(0, duration.inMilliseconds)
                                .toDouble(),
                            onChanged: (value) {
                              _videoController!.seekTo(
                                Duration(milliseconds: value.toInt()),
                              );
                            },
                          ),
                        ),

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
                              '${_formatDuration(position)} / ${_formatDuration(duration)}',
                              style: const TextStyle(color: Colors.white),
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