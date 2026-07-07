import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../supabase/supabase_client.dart';
import 'package:video_player/video_player.dart';
//import 'package:video_compress/video_compress.dart';

class SubirImagenCarrucelPage extends StatefulWidget {
  const SubirImagenCarrucelPage({super.key});

  @override
  State<SubirImagenCarrucelPage> createState() =>
      _SubirImagenCarrucelPageState();
}

class _SubirImagenCarrucelPageState
    extends State<SubirImagenCarrucelPage> {
  File? imagen;
  File? video;
  bool esVideo = false;
  bool subiendo = false;
  VideoPlayerController? _videoController;

  final ImagePicker picker = ImagePicker();

  // 📸 SELECCIONAR IMAGEN
  Future<void> seleccionarImagen() async {
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    _videoController?.dispose();
    _videoController = null;

    setState(() {
      imagen = File(picked.path);
      video = null;
      esVideo = false;
    });
  }

  // 🎥 SELECCIONAR VIDEO
  Future<void> seleccionarVideo() async {
    final XFile? picked =
        await picker.pickVideo(source: ImageSource.gallery);

    if (picked == null) return;

    _videoController?.dispose();

    final controller = VideoPlayerController.file(File(picked.path));
    await controller.initialize();
    controller.setLooping(true);
    controller.play();

    setState(() {
      video = File(picked.path);
      imagen = null;
      esVideo = true;
      _videoController = controller;
    });
  }
  Future<File> comprimirVideo(File videoOriginal) async {
  return videoOriginal;
}

  // SUBIR A SUPABASE STORAGE + BD
  Future<void> subirImagen() async {
    if (imagen == null && video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una imagen o video primero')),
      );
      return;
    }

    setState(() => subiendo = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final extension = esVideo ? 'mp4' : 'jpg';

      final nombreArchivo =
          'carrusel_${DateTime.now().millisecondsSinceEpoch}.$extension';

      File archivo;

if (esVideo) {
  archivo = await comprimirVideo(video!);
} else {
  archivo = imagen!;
}

      await SupabaseConfig.client.storage
          .from('carrusel')
          .uploadBinary(
            nombreArchivo,
            await archivo.readAsBytes(),
          );

      final imageUrl = SupabaseConfig.client.storage
          .from('carrusel')
          .getPublicUrl(nombreArchivo);

      await SupabaseConfig.client.from('carrusel_imagenes').insert({
  'image_url': imageUrl,
  'creado_por': user.id,
  'activo': true,
  'orden': 0,
  'es_video': esVideo,
  'mime_type': esVideo ? 'video/mp4' : 'image/jpeg',
});


      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archivo subido correctamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => subiendo = false);
    }
  }
  

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir imagen al carrusel'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            video != null && _videoController != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 400,
          width: double.infinity,
          color: const Color.fromARGB(255, 175, 174, 174),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
      )
                : imagen != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          imagen!,
                          height: 400,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        height: 400,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 168, 164, 164),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('No hay imagen o video seleccionado'),
                        ),
                      ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text('Seleccionar imagen'),
              onPressed: seleccionarImagen,
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.videocam),
              label: const Text('Seleccionar video'),
              onPressed: seleccionarVideo,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                icon: subiendo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: const Text('Subir archivo'),
                onPressed: subiendo ? null : subirImagen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
