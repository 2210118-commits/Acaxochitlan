import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../supabase/supabase_client.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class PublicacionesPage extends StatefulWidget {
  @override
  State<PublicacionesPage> createState() => _PublicacionesPageState();
}

class _PublicacionesPageState extends State<PublicacionesPage> {
  bool loading = true;
  List publicaciones = [];

  @override
  void initState() {
    super.initState();
    cargarPublicaciones();
  }

  Future<void> cargarPublicaciones() async {
    try {
      final res = await SupabaseConfig.client
          .from('publicaciones')
          .select()
          .order('fecha_creacion', ascending: false);

      setState(() {
        publicaciones = res;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error cargarPublicaciones: $e");
      setState(() => loading = false);
    }
  }

  // ================== UTIL ==================
  String _fileNameFromUrl(String url) {
    return Uri.parse(url).pathSegments.last;
  }

  // ================== CONFIRMAR ELIMINAR ==================
  void confirmarEliminar(String id, List imagenes) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar publicación"),
        content: const Text(
          "¿Estás seguro de eliminar esta publicación?\n\nEsta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await eliminarPublicacion(id, imagenes);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  // ================== ELIMINAR PUBLICACIÓN + IMÁGENES ==================
  Future<void> eliminarPublicacion(String id, List imagenes) async {
    final storage =
        SupabaseConfig.client.storage.from('imagenes');

    try {
      for (String url in imagenes) {
        final fileName = _fileNameFromUrl(url);
        await storage.remove([fileName]);
      }

      await SupabaseConfig.client
          .from('publicaciones')
          .delete()
          .eq('id', id);

      cargarPublicaciones();
    } catch (e) {
      debugPrint("Error eliminarPublicacion: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al eliminar la publicación"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
// editar
void editarPublicacion(Map pub) {
  final tituloCtrl = TextEditingController(text: pub['titulo']);
  final descCtrl = TextEditingController(text: pub['descripcion']);

  List<dynamic> imagenes = List<dynamic>.from(pub['imagenes'] ?? []);
  List<dynamic> videos = List<dynamic>.from(pub['videos'] ?? []);

  final imageStorage = SupabaseConfig.client.storage.from('imagenes');
  final videoStorage = SupabaseConfig.client.storage.from('videos');

  String uniqueName(String ext) =>
      "${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}.$ext";

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          bool guardando = false;
          double progreso = 0.0;
          int totalTareas = 0;
          int completadas = 0;

          void avanzar() {
            completadas++;
            setModalState(() {
              progreso = completadas / totalTareas;
            });
          }

          // ====== PICKERS DE IMAGENES Y VIDEOS ============
          Future<void> pickImages() async {
            final picker = ImagePicker();
            final picked = await picker.pickMultiImage();
            if (picked.isNotEmpty) {
              setModalState(() {
                imagenes.addAll(picked.map((x) => File(x.path)));
              });
            }
          }

          Future<void> pickVideo() async {
            final picker = ImagePicker();
            final picked = await picker.pickVideo(source: ImageSource.gallery);
            if (picked != null) {
              setModalState(() {
                videos.add(File(picked.path));
              });
            }
          }

          // ================= GUARDAR =================
          Future<void> guardarCambios() async {
            if (guardando) return;

            setModalState(() {
              guardando = true;
              progreso = 0;
              completadas = 0;
            });

            try {
              List<String> imagenesFinales = [];
              List<String> videosFinales = [];
              List<Future> uploads = [];

              final nuevasImgs = imagenes.where((e) => e is File).length;
              final nuevosVids = videos.where((e) => e is File).length;
              totalTareas = nuevasImgs + nuevosVids + 1;

              /// ========= IMÁGENES =========
              for (var img in imagenes) {
                if (img is String) {
                  imagenesFinales.add(img);
                } else if (img is File) {
                  final name = uniqueName("jpg");
                  uploads.add(
                    imageStorage
                        .upload(
                          name,
                          img,
                          fileOptions:
                              const FileOptions(contentType: 'image/jpeg'),
                        )
                        .then((_) {
                      imagenesFinales.add(
                        imageStorage.getPublicUrl(name),
                      );
                      avanzar();
                    }),
                  );
                }
              }

              /// ========= VIDEOS =========
              for (var vid in videos) {
                if (vid is String) {
                  videosFinales.add(vid);
                } else if (vid is File) {
                  final name = uniqueName("mp4");
                  uploads.add(
                    videoStorage
                        .upload(
                          name,
                          vid,
                          fileOptions:
                              const FileOptions(contentType: 'video/mp4'),
                        )
                        .then((_) {
                      videosFinales.add(
                        videoStorage.getPublicUrl(name),
                      );
                      avanzar();
                    }),
                  );
                }
              }

              await Future.wait(uploads);

              /// ========= UPDATE =========
              await SupabaseConfig.client.from('publicaciones').update({
                'titulo': tituloCtrl.text.trim(),
                'descripcion': descCtrl.text.trim(),
                'imagenes': imagenesFinales,
                'videos': videosFinales,
              }).eq('id', pub['id']);

              avanzar();

              Navigator.pop(dialogContext);
              cargarPublicaciones();
            } catch (e, s) {
              debugPrint("❌ Error guardarCambios: $e");
              debugPrintStack(stackTrace: s);
            } finally {
              setModalState(() => guardando = false);
            }
          }

          // ================= IMAGENES Y VIDEOS EN MINIATURAS =================
          Widget imageThumb(dynamic img) {
            return Stack(
              children: [
                img is String
                    ? Image.network(img, width: 80, height: 80, fit: BoxFit.cover)
                    : Image.file(img, width: 80, height: 80, fit: BoxFit.cover),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      setModalState(() => imagenes.remove(img));
                    },
                    child: const CircleAvatar(
                      radius: 12,
                      child: Icon(Icons.close, size: 14),
                    ),
                  ),
                )
              ],
            );
          }

          Widget videoThumb(dynamic vid) {
            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerPage(video: vid),
                      ),
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.black,
                    child: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      setModalState(() => videos.remove(vid));
                    },
                    child: const CircleAvatar(
                      radius: 12,
                      child: Icon(Icons.close, size: 14),
                    ),
                  ),
                ),
              ],
            );
          }

          // ================= UI =================
          return Stack(
            children: [
              AlertDialog(
                title: const Text("Editar publicación"),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: tituloCtrl,
                        decoration:
                            const InputDecoration(labelText: "Título"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(labelText: "Descripción"),
                      ),
                      const SizedBox(height: 15),
                      const Text("Imágenes"),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: imagenes.map(imageThumb).toList(),
                      ),
                      const SizedBox(height: 10),
                      const Text("Videos"),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: videos.map(videoThumb).toList(),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: pickImages,
                        icon: const Icon(Icons.image),
                        label: const Text("Agregar imágenes"),
                      ),
                      ElevatedButton.icon(
                        onPressed: pickVideo,
                        icon: const Icon(Icons.videocam),
                        label: const Text("Agregar video"),
                      ),
                      if (guardando) ...[
                        const SizedBox(height: 15),
                        LinearProgressIndicator(value: progreso),
                        const SizedBox(height: 6),
                        Text("${(progreso * 100).toStringAsFixed(0)} %"),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        guardando ? null : () => Navigator.pop(dialogContext),
                    child: const Text("Cancelar"),
                  ),
                  ElevatedButton(
                    onPressed: guardando ? null : guardarCambios,
                    child: const Text("Guardar"),
                  ),
                ],
              ),

              /// 🔒 OVERLAY DE CARGA
              if (guardando)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}

  

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Publicaciones")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: publicaciones.length,
              itemBuilder: (context, index) {
                final pub = publicaciones[index];
                final List imagenes = pub['imagenes'] ?? [];
                final List videos = pub['videos'] ?? [];


                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                pub['titulo'],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'editar') {
                                  editarPublicacion(pub);
                                } else if (value == 'eliminar') {
                                  confirmarEliminar(
                                      pub['id'], imagenes);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'editar',
                                    child: Text("Editar")),
                                PopupMenuItem(
                                  value: 'eliminar',
                                  child: Text(
                                    "Eliminar",
                                    style:
                                        TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(pub['descripcion']),
                        const SizedBox(height: 10),

                        if (imagenes.isNotEmpty)
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: imagenes.length,
                              itemBuilder: (_, i) => Padding(
                                padding:
                                    const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  child: Image.network(
                                    imagenes[i],
                                    width: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (videos.isNotEmpty)
  Column(
    children: videos.map<Widget>((url) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VideoItem(url: url),
        ),
      );
    }).toList(),
  ),


                        const SizedBox(height: 8),
                        Text(
                          pub['fecha_creacion']
                              .toString()
                              .substring(0, 16),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
  
}
class VideoItem extends StatefulWidget {
  final String url;
  const VideoItem({required this.url});

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          Icon(
            _controller.value.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_fill,
            size: 60,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final dynamic video;

  const VideoPlayerPage({super.key, required this.video});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = widget.video is String
        ? VideoPlayerController.networkUrl(Uri.parse(widget.video))
        : VideoPlayerController.file(widget.video);

    controller.initialize().then((_) {
      setState(() {});
      controller.play();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video")),
      body: Center(
        child: controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
