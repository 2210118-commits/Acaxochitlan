import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../editar_noticia_page.dart';

class AdminNoticiasPage extends StatefulWidget {
  const AdminNoticiasPage({super.key});

  @override
  State<AdminNoticiasPage> createState() =>
      _AdminNoticiasPageState();
}

class _AdminNoticiasPageState
    extends State<AdminNoticiasPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController tituloController =
      TextEditingController();

  final TextEditingController descripcionController =
      TextEditingController();

  final TextEditingController ubicacionController =
    TextEditingController();

final TextEditingController latitudController =
    TextEditingController();

final TextEditingController longitudController =
    TextEditingController();

  final ImagePicker picker = ImagePicker();

  String obtenerCarpetaNoticia() {
  final titulo = tituloController.text.trim();

  if (titulo.isEmpty) {
    return 'noticia_${DateTime.now().millisecondsSinceEpoch}';
  }

  return titulo
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll(RegExp(r'[^a-z0-9_]'), '');
}

  File? imagenSeleccionada;

  List<File> imagenesExtra = [];
  List<TextEditingController> descripcionesImagenes = [];

  List<File> videosSeleccionados = [];

  bool subiendo = false;
  bool cargandoNoticias = true;

  String categoriaSeleccionada = 'Noticias';
  String? noticiaEditandoId;

  List<dynamic> noticias = [];

  @override
  void initState() {
    super.initState();
    cargarNoticias();
  }

  Future<void> cargarNoticias() async {
    try {
      final response = await supabase
          .from('noticias')
          .select()
          .order('fecha', ascending: false);

      if (!mounted) return;

      setState(() {
        noticias = response;
        cargandoNoticias = false;
      });
    } catch (e) {
      debugPrint('Error noticias: $e');
    }
  }

  Future<void> seleccionarImagenPrincipal() async {
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imagen == null) return;

    setState(() {
      imagenSeleccionada = File(imagen.path);
    });
  }

  Future<void> agregarImagenExtra() async {
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imagen == null) return;

    setState(() {
      imagenesExtra.add(File(imagen.path));
      descripcionesImagenes.add(
        TextEditingController(),
      );
    });
  }

  Future<void> agregarVideo() async {
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (video == null) return;

    setState(() {
      videosSeleccionados.add(File(video.path));
    });
  }

  Future<String?> subirImagenPrincipal() async {
  if (imagenSeleccionada == null) return null;

  try {
    final carpeta = obtenerCarpetaNoticia();

    final nombre =
        '$carpeta/principal.jpg';

    await supabase.storage
        .from('noticias')
        .upload(
          nombre,
          imagenSeleccionada!,
          fileOptions: const FileOptions(
            upsert: true,
          ),
        );

    return supabase.storage
        .from('noticias')
        .getPublicUrl(nombre);
  } catch (e) {
    debugPrint('Error imagen principal: $e');
    return null;
  }
}

  Future<List<Map<String, dynamic>>> subirGaleria() async {
  List<Map<String, dynamic>> galeria = [];

  final carpeta = obtenerCarpetaNoticia();

  for (int i = 0; i < imagenesExtra.length; i++) {
    try {
      final nombre =
          '$carpeta/galeria_${i + 1}.jpg';

      await supabase.storage
          .from('noticias')
          .upload(
            nombre,
            imagenesExtra[i],
            fileOptions: const FileOptions(
              upsert: true,
            ),
          );

      final url = supabase.storage
          .from('noticias')
          .getPublicUrl(nombre);

      galeria.add({
        'imagen': url,
        'descripcion':
            descripcionesImagenes[i].text.trim(),
      });
    } catch (e) {
      debugPrint('Error galería: $e');
    }
  }

  return galeria;
}
  Future<List<String>> subirVideos() async {
  List<String> urls = [];

  final carpeta = obtenerCarpetaNoticia();

  for (int i = 0; i < videosSeleccionados.length; i++) {
    try {
      final nombre =
          '$carpeta/video_${i + 1}.mp4';

      await supabase.storage
          .from('noticias')
          .upload(
            nombre,
            videosSeleccionados[i],
            fileOptions: const FileOptions(
              upsert: true,
            ),
          );

      final url = supabase.storage
          .from('noticias')
          .getPublicUrl(nombre);

      urls.add(url);
    } catch (e) {
      debugPrint('Error video: $e');
    }
  }

  return urls;
}

  Future<void> guardarNoticia() async {
  if (tituloController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Escribe un título'),
      ),
    );
    return;
  }

  setState(() {
    subiendo = true;
  });

  try {
    String? imagenUrl;

    if (imagenSeleccionada != null) {
      imagenUrl = await subirImagenPrincipal();
    }

    final galeria = await subirGaleria();
    final videos = await subirVideos();

    if (noticiaEditandoId == null) {
      await supabase.from('noticias').insert({
        'titulo': tituloController.text.trim(),
        'descripcion':
            descripcionController.text.trim(),
        'ubicacion': ubicacionController.text.trim(),
'latitud': double.tryParse(
    latitudController.text.trim()),
'longitud': double.tryParse(
    longitudController.text.trim()),
        'imagen': imagenUrl,
        'categoria': categoriaSeleccionada,
        'galeria': galeria,
        'videos': videos,
      });
    } else {
      final updateData = {
        'titulo': tituloController.text.trim(),
        'descripcion':
            descripcionController.text.trim(),
        'categoria': categoriaSeleccionada,
        'galeria': galeria,
        'videos': videos,
      };

      if (imagenUrl != null) {
        updateData['imagen'] = imagenUrl;
      }

      await supabase
          .from('noticias')
          .update(updateData)
          .eq('id', noticiaEditandoId!);
    }

    tituloController.clear();
    descripcionController.clear();

    for (var c in descripcionesImagenes) {
      c.dispose();
    }

    setState(() {
      imagenSeleccionada = null;
      imagenesExtra.clear();
      videosSeleccionados.clear();
      descripcionesImagenes.clear();
      noticiaEditandoId = null;
    });

    await cargarNoticias();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Noticia guardada correctamente',
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error guardando noticia: $e');
  }

  if (!mounted) return;

  setState(() {
    subiendo = false;
  });
}

  Future<void> eliminarNoticia(
  String id,
  Map noticia,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Eliminar noticia'),
      content: const Text(
        'Se eliminará toda la noticia, imágenes y videos. ¿Continuar?',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (confirmar != true) return;

  try {
    final List<String> archivos = [];

    final imagenPrincipal =
        noticia['imagen']?.toString();

    if (imagenPrincipal != null &&
        imagenPrincipal.isNotEmpty) {
      final ruta = imagenPrincipal.split(
        '/noticias/',
      );

      if (ruta.length > 1) {
        archivos.add(ruta[1]);
      }
    }

    final List galeria =
        noticia['galeria'] ?? [];

    for (var item in galeria) {
      final url =
          item['imagen']?.toString();

      if (url != null &&
          url.isNotEmpty) {
        final ruta =
            url.split('/noticias/');

        if (ruta.length > 1) {
          archivos.add(ruta[1]);
        }
      }
    }

    final List videos =
        noticia['videos'] ?? [];

    for (var video in videos) {
      final url = video.toString();

      if (url.isNotEmpty) {
        final ruta =
            url.split('/noticias/');

        if (ruta.length > 1) {
          archivos.add(ruta[1]);
        }
      }
    }

    if (archivos.isNotEmpty) {
      await supabase.storage
          .from('noticias')
          .remove(archivos);
    }

    await supabase
        .from('noticias')
        .delete()
        .eq('id', id);

    await cargarNoticias();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Noticia eliminada completamente',
        ),
      ),
    );
  } catch (e) {
    debugPrint(
      'Error eliminando noticia: $e',
    );
  }
}

  Widget _cardNoticia(Map noticia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (noticia['imagen'] != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                noticia['imagen'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        noticia['categoria'] ??
                            'Noticias',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                          ),
                          onPressed: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditarNoticiaPage(
        noticia: noticia,
      ),
    ),
  );

  cargarNoticias();
},
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            eliminarNoticia(
  noticia['id'],
  noticia,
);
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  noticia['titulo'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  noticia['descripcion'] ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),


                if (noticia['galeria'] != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 12,
                    ),
                    child: Text(
                      'Galería: ${(noticia['galeria'] as List).length} imágenes',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                if (noticia['videos'] != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 6,
                    ),
                    child: Text(
                      'Videos: ${(noticia['videos'] as List).length}',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar noticias'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Publicar noticia',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// IMAGEN PRINCIPAL
            InkWell(
              onTap: seleccionarImagenPrincipal,
              borderRadius:
                  BorderRadius.circular(18),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                ),
                child: imagenSeleccionada != null
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        child: Image.file(
                          imagenSeleccionada!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Seleccionar imagen principal',
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            /// AGREGAR IMAGEN EXTRA
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: agregarImagenExtra,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text(
                  'Agregar imagen extra',
                ),
              ),
            ),

            const SizedBox(height: 12),

            ...List.generate(
              imagenesExtra.length,
              (index) => Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 16,
                ),
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      child: Image.file(
                        imagenesExtra[index],
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller:
                          descripcionesImagenes[
                              index],
                      decoration:
                          InputDecoration(
                        labelText:
                            'Descripción de esta imagen',
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// VIDEOS
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: agregarVideo,
                icon: const Icon(
                  Icons.video_library,
                ),
                label: const Text(
                  'Agregar video',
                ),
              ),
            ),

            const SizedBox(height: 12),

            ...List.generate(
              videosSeleccionados.length,
              (index) => Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.videocam,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Video ${index + 1}',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// TITULO
            TextField(
              controller: tituloController,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// DESCRIPCION
            TextField(
              controller:
                  descripcionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText:
                    'Descripción principal',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),

TextField(
  controller: ubicacionController,
  decoration: InputDecoration(
    labelText: '¿Cómo llegar?',
    prefixIcon: Icon(Icons.location_on),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
),

const SizedBox(height: 16),

TextField(
  controller: latitudController,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    labelText: 'Latitud',
    prefixIcon: Icon(Icons.map),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
),

const SizedBox(height: 16),

TextField(
  controller: longitudController,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    labelText: 'Longitud',
    prefixIcon: Icon(Icons.map_outlined),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
),
            

            /// CATEGORIA
            DropdownButtonFormField<String>(
              value: categoriaSeleccionada,
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Noticias',
                  child: Text('Noticias'),
                ),
                DropdownMenuItem(
                  value: 'Eventos',
                  child: Text('Eventos'),
                ),
                DropdownMenuItem(
                  value: 'Avisos',
                  child: Text('Avisos'),
                ),
                DropdownMenuItem(
                  value: 'Atractivos Turísticos',
                  child: Text('Atractivos Turísticos'),
                ),
                DropdownMenuItem(
  value: 'Ver más',
  child: Text('Ver más'),
),
              ],
              onChanged: (value) {
                setState(() {
                  categoriaSeleccionada =
                      value!;
                });
              },
            ),

            const SizedBox(height: 20),

            /// PUBLICAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    subiendo ? null : guardarNoticia,
                icon: subiendo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.cloud_upload,
                      ),
                label: Text(
                  subiendo
                      ? 'Publicando...'
                      : 'Publicar noticia',
                ),
                style:
                    ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  backgroundColor:
                      Colors.deepPurple,
                  foregroundColor:
                      Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 35),

            const Text(
              'Noticias publicadas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            if (cargandoNoticias)
              const Center(
                child:
                    CircularProgressIndicator(),
              ),

            ...noticias.map(
              (n) => _cardNoticia(n),
            ),
          ],
        ),
      ),
    );
  }
}