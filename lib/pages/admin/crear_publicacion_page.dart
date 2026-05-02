import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../supabase/supabase_client.dart';

class CrearPublicacionPage extends StatefulWidget {
  @override
  _CrearPublicacionPageState createState() => _CrearPublicacionPageState();
}

class _CrearPublicacionPageState extends State<CrearPublicacionPage> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  List<File> imagenes = [];
  List<File> videos = [];
  List<VideoPlayerController> _videoControllers = [];

  bool loading = false;
  String errorMessage = "";

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      final files = picked.map((x) => File(x.path)).toList();

      if (imagenes.length + files.length > 30) {
        setState(() => errorMessage = "Máximo permitido: 30 imágenes.");
        return;
      }

      setState(() => imagenes.addAll(files));
    }
  }

  Future<void> pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final controller = VideoPlayerController.file(file);

    await controller.initialize();
    controller.setLooping(true);

    setState(() {
      videos.add(file);
      _videoControllers.add(controller);
    });
  }

  Future<void> publicar() async {
    if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty) {
      setState(() => errorMessage = "Título y descripción son obligatorios.");
      return;
    }

    setState(() {
      loading = true;
      errorMessage = "";
    });

    try {
      List<String> imagenesUrls = [];
      List<String> videosUrls = [];

      // 🔹 IMÁGENES (SIN CAMBIOS)
      if (imagenes.isNotEmpty) {
        final storage = SupabaseConfig.client.storage.from('imagenes');

        for (int i = 0; i < imagenes.length; i++) {
          final img = imagenes[i];
          final fileName =
              "img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg";

          final bytes = await img.readAsBytes();
          await storage.uploadBinary(fileName, bytes);

          imagenesUrls.add(storage.getPublicUrl(fileName));
        }
      }

      // 🔹 VIDEOS (ÚNICO CAMBIO AQUÍ)
      if (videos.isNotEmpty) {
        final storage = SupabaseConfig.client.storage.from('videos');

        for (int i = 0; i < videos.length; i++) {
          final vid = videos[i];
          final fileName =
              "vid_${DateTime.now().millisecondsSinceEpoch}_$i.mp4";

          // ✅ CAMBIO CORRECTO
          final bytes = await vid.readAsBytes();
await storage.uploadBinary(fileName, bytes);

          videosUrls.add(storage.getPublicUrl(fileName));
        }
      }

      // ✅ GUARDAR PUBLICACIÓN (PRIMERO Y SOLO)
await SupabaseConfig.client.from('publicaciones').insert({
  'titulo': titleCtrl.text.trim(),
  'descripcion': descCtrl.text.trim(),
  'imagenes': imagenesUrls.isEmpty ? [] : imagenesUrls,
  'videos': videosUrls.isEmpty ? [] : videosUrls,
});

// ✅ NOTIFICACIÓN (SEPARADO)

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
  print("ERROR COMPLETO: $e");
  setState(() => errorMessage = e.toString());
}

    setState(() => loading = false);
  }

  @override
  void dispose() {
    for (var c in _videoControllers) {
      c.dispose();
    }
    titleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Publicación")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: imagenes.map((img) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      img,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => imagenes.remove(img)),
                      child: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  )
                ],
              )).toList(),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: pickImages,
              icon: const Icon(Icons.image),
              label: const Text("Seleccionar imagenes"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: pickVideo,
              icon: const Icon(Icons.videocam),
              label: const Text("Agregar video"),
            ),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _videoControllers.length,
              itemBuilder: (context, index) {
                final controller = _videoControllers[index];
                return Column(
                  children: [
                    AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            videos[index].path.split('/').last,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              controller.dispose();
                              _videoControllers.removeAt(index);
                              videos.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                  ],
                );
              },
            ),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: loading ? null : publicar,
              icon: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(loading ? "Publicando..." : "Publicar"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
