import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditarNoticiaPage extends StatefulWidget {
  final Map noticia;

  const EditarNoticiaPage({
    super.key,
    required this.noticia,
  });

  @override
  State<EditarNoticiaPage> createState() =>
      _EditarNoticiaPageState();
}

class _EditarNoticiaPageState
    extends State<EditarNoticiaPage> {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  late TextEditingController tituloController;
  late TextEditingController descripcionController;
  late TextEditingController ubicacionController;
late TextEditingController latitudController;
late TextEditingController longitudController;

  String categoriaSeleccionada = 'Noticias';

  File? nuevaImagenPrincipal;

  List<Map<String, dynamic>> galeriaExistente = [];
  List<String> videosExistentes = [];

  List<File> nuevasImagenes = [];
  List<TextEditingController>
      nuevasDescripciones = [];

  List<File> nuevosVideos = [];

  bool guardando = false;

  @override
  void initState() {
    super.initState();

    tituloController = TextEditingController(
      text: widget.noticia['titulo'] ?? '',
    );

    descripcionController =
        TextEditingController(
      text:
          widget.noticia['descripcion'] ?? '',
    );

    ubicacionController =
    TextEditingController(
  text: widget.noticia['ubicacion'] ?? '',
);

latitudController =
    TextEditingController(
  text: widget.noticia['latitud']?.toString() ?? '',
);

longitudController =
    TextEditingController(
  text: widget.noticia['longitud']?.toString() ?? '',
);

    categoriaSeleccionada =
        widget.noticia['categoria'] ??
            'Noticias';

    galeriaExistente =
        List<Map<String, dynamic>>.from(
      widget.noticia['galeria'] ?? [],
    );

    videosExistentes = List<String>.from(
      widget.noticia['videos'] ?? [],
    );
  }

  String obtenerCarpetaNoticia() {
    final titulo = tituloController.text.trim();

    if (titulo.isEmpty) {
      return widget.noticia['id'];
    }

    return titulo
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(
          RegExp(r'[^a-z0-9_]'),
          '',
        );
  }

  Future<void>
      seleccionarImagenPrincipal() async {
    final imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imagen == null) return;

    setState(() {
      nuevaImagenPrincipal =
          File(imagen.path);
    });
  }

  Future<void> agregarImagenNueva() async {
    final imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imagen == null) return;

    setState(() {
      nuevasImagenes.add(
        File(imagen.path),
      );

      nuevasDescripciones.add(
        TextEditingController(),
      );
    });
  }

  Future<void> agregarVideoNuevo() async {
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (video == null) return;

    setState(() {
      nuevosVideos.add(
        File(video.path),
      );
    });
  }

  Future<String?> subirImagenPrincipal() async {
    if (nuevaImagenPrincipal == null) {
      return widget.noticia['imagen'];
    }

    final carpeta = obtenerCarpetaNoticia();

    final ruta =
        '$carpeta/principal.jpg';

    await supabase.storage
        .from('noticias')
        .upload(
          ruta,
          nuevaImagenPrincipal!,
          fileOptions:
              const FileOptions(
            upsert: true,
          ),
        );

    return supabase.storage
        .from('noticias')
        .getPublicUrl(ruta);
  }

  Future<List<Map<String, dynamic>>>
      subirNuevasImagenes() async {
    List<Map<String, dynamic>> nuevas = [];

    final carpeta = obtenerCarpetaNoticia();

    for (int i = 0;
        i < nuevasImagenes.length;
        i++) {
      final ruta =
          '$carpeta/galeria_nueva_$i.jpg';

      await supabase.storage
          .from('noticias')
          .upload(
            ruta,
            nuevasImagenes[i],
            fileOptions:
                const FileOptions(
              upsert: true,
            ),
          );

      final url = supabase.storage
          .from('noticias')
          .getPublicUrl(ruta);

      nuevas.add({
        'imagen': url,
        'descripcion':
            nuevasDescripciones[i]
                .text
                .trim(),
      });
    }

    return nuevas;
  }

  Future<List<String>>
      subirNuevosVideos() async {
    List<String> nuevos = [];

    final carpeta = obtenerCarpetaNoticia();

    for (int i = 0;
        i < nuevosVideos.length;
        i++) {
      final ruta =
          '$carpeta/video_nuevo_$i.mp4';

      await supabase.storage
          .from('noticias')
          .upload(
            ruta,
            nuevosVideos[i],
            fileOptions:
                const FileOptions(
              upsert: true,
            ),
          );

      nuevos.add(
        supabase.storage
            .from('noticias')
            .getPublicUrl(ruta),
      );
    }

    return nuevos;
  }

  void eliminarImagenGaleria(
    int index,
  ) {
    setState(() {
      galeriaExistente.removeAt(index);
    });
  }

  void eliminarVideoExistente(
    int index,
  ) {
    setState(() {
      videosExistentes.removeAt(index);
    });
  }

  void eliminarNuevaImagen(
    int index,
  ) {
    setState(() {
      nuevasImagenes.removeAt(index);
      nuevasDescripciones
          .removeAt(index);
    });
  }

  void eliminarNuevoVideo(
    int index,
  ) {
    setState(() {
      nuevosVideos.removeAt(index);
    });
  }
    Future<void> actualizarNoticia() async {
    setState(() {
      guardando = true;
    });

    try {
      final imagenPrincipal =
          await subirImagenPrincipal();

      final nuevasGaleria =
          await subirNuevasImagenes();

      final nuevosVideosUrls =
          await subirNuevosVideos();

      final galeriaFinal = [
        ...galeriaExistente,
        ...nuevasGaleria,
      ];

      final videosFinal = [
        ...videosExistentes,
        ...nuevosVideosUrls,
      ];

      await supabase
    .from('noticias')
    .update({
      'titulo': tituloController.text.trim(),
      'descripcion':
          descripcionController.text.trim(),
      'categoria': categoriaSeleccionada,
      'ubicacion':
          ubicacionController.text.trim(),
      'latitud': double.tryParse(
          latitudController.text.trim()),
      'longitud': double.tryParse(
          longitudController.text.trim()),
      'imagen': imagenPrincipal,
      'galeria': galeriaFinal,
      'videos': videosFinal,
    })
          .eq('id', widget.noticia['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Noticia actualizada correctamente',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        'Error actualizando noticia: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      guardando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Editar noticia'),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            /// IMAGEN PRINCIPAL
            const Text(
              'Imagen principal',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  child: nuevaImagenPrincipal !=
                          null
                      ? Image.file(
                          nuevaImagenPrincipal!,
                          height: 220,
                          width:
                              double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          widget.noticia[
                                  'imagen'] ??
                              '',
                          height: 220,
                          width:
                              double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),

                Positioned(
                  right: 10,
                  top: 10,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Colors.blue,
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color:
                                Colors.white,
                          ),
                          onPressed:
                              seleccionarImagenPrincipal,
                        ),
                      ),

                      const SizedBox(
                          width: 8),

                      CircleAvatar(
                        backgroundColor:
                            Colors.red,
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color:
                                Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              nuevaImagenPrincipal =
                                  null;

                              widget.noticia[
                                  'imagen'] = '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// GALERIA EXISTENTE
            const Text(
              'Galería',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...List.generate(
              galeriaExistente.length,
              (index) {
                final item =
                    galeriaExistente[index];

                return Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 16,
                  ),
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade100,
                    borderRadius:
                        BorderRadius
                            .circular(16),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                        child:
                            Image.network(
                          item['imagen'],
                          height: 180,
                          width: double
                              .infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(
                          height: 10),

                      TextFormField(
                        initialValue:
                            item[
                                    'descripcion'] ??
                                '',
                        onChanged:
                            (value) {
                          galeriaExistente[
                                  index]
                              [
                              'descripcion'] = value;
                        },
                        decoration:
                            InputDecoration(
                          labelText:
                              'Descripción',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 10),

                      ElevatedButton.icon(
                        onPressed: () =>
                            eliminarImagenGaleria(
                          index,
                        ),
                        icon: const Icon(
                          Icons.delete,
                        ),
                        label:
                            const Text(
                          'Eliminar imagen',
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red,
                          foregroundColor:
                              Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            OutlinedButton.icon(
              onPressed:
                  agregarImagenNueva,
              icon: const Icon(
                Icons.add_photo_alternate,
              ),
              label: const Text(
                'Agregar imagen nueva',
              ),
            ),

            const SizedBox(height: 20),

            ...List.generate(
              nuevasImagenes.length,
              (index) => Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 16,
                ),
                child: Column(
                  children: [
                    Image.file(
                      nuevasImagenes[
                          index],
                      height: 180,
                      width:
                          double.infinity,
                      fit: BoxFit.cover,
                    ),

                    const SizedBox(
                        height: 10),

                    TextField(
                      controller:
                          nuevasDescripciones[
                              index],
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Descripción nueva',
                      ),
                    ),

                    TextButton.icon(
                      onPressed: () =>
                          eliminarNuevaImagen(
                        index,
                      ),
                      icon: const Icon(
                        Icons.delete,
                      ),
                      label: const Text(
                        'Eliminar',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

TextField(
  controller: ubicacionController,
  maxLines: 3,
  decoration: const InputDecoration(
    labelText: '¿Cómo llegar?',
    prefixIcon: Icon(Icons.location_on),
  ),
),

const SizedBox(height: 20),

TextField(
  controller: latitudController,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
  ),
  decoration: const InputDecoration(
    labelText: 'Latitud',
    prefixIcon: Icon(Icons.map),
  ),
),

const SizedBox(height: 20),

TextField(
  controller: longitudController,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
  ),
  decoration: const InputDecoration(
    labelText: 'Longitud',
    prefixIcon: Icon(Icons.map_outlined),
  ),
),

            /// VIDEOS
            const Text(
              'Videos',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...List.generate(
              videosExistentes.length,
              (index) => ListTile(
                leading: const Icon(
                  Icons.videocam,
                ),
                title: Text(
                  'Video ${index + 1}',
                ),
                trailing:
                    IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () =>
                      eliminarVideoExistente(
                    index,
                  ),
                ),
              ),
            ),

            OutlinedButton.icon(
              onPressed:
                  agregarVideoNuevo,
              icon: const Icon(
                Icons.video_library,
              ),
              label: const Text(
                'Agregar video nuevo',
              ),
            ),

            const SizedBox(height: 20),

            ...List.generate(
              nuevosVideos.length,
              (index) => ListTile(
                leading: const Icon(
                  Icons.movie,
                ),
                title: Text(
                  'Nuevo video ${index + 1}',
                ),
                trailing:
                    IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () =>
                      eliminarNuevoVideo(
                    index,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// TITULO
            TextField(
              controller:
                  tituloController,
              decoration:
                  const InputDecoration(
                labelText: 'Título',
              ),
            ),

            const SizedBox(height: 20),

            /// DESCRIPCION
            TextField(
              controller:
                  descripcionController,
              maxLines: 5,
              decoration:
                  const InputDecoration(
                labelText:
                    'Descripción',
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value:
                  categoriaSeleccionada,
              items: const [
                DropdownMenuItem(
                  value: 'Noticias',
                  child:
                      Text('Noticias'),
                ),
                DropdownMenuItem(
                  value: 'Eventos',
                  child:
                      Text('Eventos'),
                ),
                DropdownMenuItem(
                  value: 'Avisos',
                  child:
                      Text('Avisos'),
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

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed: guardando
                    ? null
                    : actualizarNoticia,
                icon: const Icon(
                  Icons.save,
                ),
                label: Text(
                  guardando
                      ? 'Actualizando...'
                      : 'Actualizar noticia',
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}