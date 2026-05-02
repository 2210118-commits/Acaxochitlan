import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class EditarLugarPage extends StatefulWidget {
  final Map<String, dynamic> lugar;

  const EditarLugarPage({super.key, required this.lugar});

  @override
  State<EditarLugarPage> createState() => _EditarLugarPageState();
}

class _EditarLugarPageState extends State<EditarLugarPage> {
  final _formKey = GlobalKey<FormState>();

  final nombreCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final videoCtrl = TextEditingController();
  final precioCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final webCtrl = TextEditingController();
  final facebookCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  final servicioCtrl = TextEditingController();
  final actividadCtrl = TextEditingController();
  final recamaraNombreCtrl = TextEditingController();
final recamaraPrecioCtrl = TextEditingController();
  final platilloNombreCtrl = TextEditingController();
final platilloPrecioCtrl = TextEditingController();

File? platilloImagen;
File? recamaraImagen;
  String tipoSeleccionado = 'hotel';

  File? nuevaImagenPrincipal;
  File? nuevoLogo;

  List<String> galeriaExistente = [];
  List<String> videosExistentes = [];
  List<String> servicios = [];
  List<String> actividades = [];
  List<Map<String, dynamic>> recamaras = [];
  List<Map<String, dynamic>> platillos = [];

  final picker = ImagePicker();
  final uuid = const Uuid();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void agregarVideo() {
  if (videoCtrl.text.trim().isEmpty) return;

  setState(() {
    videosExistentes.add(videoCtrl.text.trim());
    videoCtrl.clear();
  });
}

String? obtenerYoutubeId(String url) {
  try {
    final uri = Uri.parse(url);

    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    }

    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }

    return null;
  } catch (e) {
    return null;
  }
}

  void _cargarDatos() {
    final l = widget.lugar;

    nombreCtrl.text = l['nombre'] ?? '';
    descripcionCtrl.text = l['descripcion'] ?? '';
    precioCtrl.text = l['precio']?.toString() ?? '';
    telefonoCtrl.text = l['telefono'] ?? '';
    webCtrl.text = l['pagina_web'] ?? '';
    facebookCtrl.text = l['facebook'] ?? '';
    latCtrl.text = l['latitud']?.toString() ?? '';
    lngCtrl.text = l['longitud']?.toString() ?? '';

    tipoSeleccionado = l['tipo'] ?? 'hotel';

    galeriaExistente = List<String>.from(l['galeria'] ?? []);
    videosExistentes = List<String>.from(l['videos'] ?? []);
    servicios = List<String>.from(l['servicios'] ?? []);
    actividades = List<String>.from(l['actividades'] ?? []);
    recamaras = List<Map<String, dynamic>>.from(l['recamaras'] ?? []);
    platillos = List<Map<String, dynamic>>.from(l['platillos'] ?? []);
  }

  String normalizarNombre(String nombre) {
  return nombre
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
}

  Future<String> uploadImagenPrincipal(File file) async {
  final storage =
      Supabase.instance.client.storage.from('hoteles_cabanas');

  final extension = file.path.split('.').last;

  // 🔥 USAR MISMA NORMALIZACIÓN
  final carpetaLugar =
    normalizarNombre(nombreCtrl.text.trim());

  final basePath = '$carpetaLugar/principal';

  final existentes = await storage.list(path: basePath);

  int numero = 1;

  for (var archivo in existentes) {
    final nombre = archivo.name;

    if (nombre.startsWith('principal')) {
      final sinExtension = nombre.split('.').first;
      final n = int.tryParse(
          sinExtension.replaceAll('principal', ''));

      if (n != null && n >= numero) {
        numero = n + 1;
      }
    }
  }

  final filePath = '$basePath/principal$numero.$extension';

  await storage.upload(filePath, file);

  return storage.getPublicUrl(filePath);
}

Future<void> agregarImagenGaleria() async {
  final images = await picker.pickMultiImage();

  if (images.isEmpty) return;

  final storage =
      Supabase.instance.client.storage.from('hoteles_cabanas');

  final carpetaLugar =
      normalizarNombre(nombreCtrl.text.trim());

  for (final img in images) {
    final file = File(img.path);
    final extension = file.path.split('.').last;

    final filePath =
        '$carpetaLugar/galeria/${uuid.v4()}.$extension';

    await storage.upload(filePath, file);

    final url = storage.getPublicUrl(filePath);

    setState(() {
      galeriaExistente.add(url);
    });
  }
}

Future<String> reemplazarArchivo(
  File file,
  String pathReal,
) async {
  final storage =
      Supabase.instance.client.storage.from('hoteles_cabanas');

  await storage.upload(
    pathReal,
    file,
    fileOptions: const FileOptions(upsert: true),
  );

  return storage.getPublicUrl(pathReal);
}

Future<String> uploadLogo(File file) async {
  final storage = Supabase.instance.client.storage.from('hoteles_cabanas');

  final extension = file.path.split('.').last;

  final fileName = 'logos/${widget.lugar['id']}.$extension';

  await storage.upload(
    fileName,
    file,
    fileOptions: const FileOptions(upsert: true),
  );

  return storage.getPublicUrl(fileName);
}

Future<void> pickImagenRecamara() async {
  final image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    setState(() {
      recamaraImagen = File(image.path);
    });
  }
}
Future<String?> uploadImagenRecamara(File file) async {
  final storage =
      Supabase.instance.client.storage.from('hoteles_cabanas');

  final extension = file.path.split('.').last;

  final carpetaLugar =
      normalizarNombre(nombreCtrl.text.trim());

  final filePath =
      '$carpetaLugar/recamaras/${uuid.v4()}.$extension';

  await storage.upload(filePath, file);

  return storage.getPublicUrl(filePath);
}

Future<String?> uploadImagenPlatillo(File file) async {
  final storage =
      Supabase.instance.client.storage.from('hoteles_cabanas');

  final extension = file.path.split('.').last;

  final carpetaLugar =
      normalizarNombre(nombreCtrl.text.trim());

  final filePath =
      '$carpetaLugar/platillos/${uuid.v4()}.$extension';

  await storage.upload(filePath, file);

  return storage.getPublicUrl(filePath);
}

Future<void> pickImagenPlatillo() async {
  final image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    setState(() {
      platilloImagen = File(image.path);
    });
  }
}

Future<void> agregarVideoDesdeTelefono() async {
  final video = await picker.pickVideo(
    source: ImageSource.gallery,
  );

  if (video == null) return;

  final file = File(video.path);
  final extension = file.path.split('.').last;

  final storage =
      Supabase.instance.client.storage.from('hoteles_cabanas');

  final carpetaLugar =
      normalizarNombre(nombreCtrl.text.trim());

  final filePath =
      '$carpetaLugar/videos/${uuid.v4()}.$extension';

  await storage.upload(filePath, file);

  final url = storage.getPublicUrl(filePath);

  setState(() {
    videosExistentes.add(url);
  });
}



Future<void> agregarRecamara() async {
  if (recamaraNombreCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El nombre de la recámara es obligatorio'),
      ),
    );
    return;
  }

  String? imagenUrl;

  if (recamaraImagen != null) {
    imagenUrl = await uploadImagenRecamara(recamaraImagen!);
  }

  setState(() {
    recamaras.add({
      'nombre': recamaraNombreCtrl.text.trim(),
      'precio': recamaraPrecioCtrl.text.trim().isEmpty
          ? null
          : recamaraPrecioCtrl.text.trim(),
      'imagen': imagenUrl,
    });

    recamaraNombreCtrl.clear();
    recamaraPrecioCtrl.clear();
    recamaraImagen = null;
  });
}

Future<void> agregarPlatillo() async {
  if (platilloNombreCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El nombre del platillo es obligatorio'),
      ),
    );
    return;
  }

  String? imagenUrl;

  if (platilloImagen != null) {
    imagenUrl = await uploadImagenPlatillo(platilloImagen!);
  }

  setState(() {
    platillos.add({
  'nombre': platilloNombreCtrl.text.trim(),
  'precio': platilloPrecioCtrl.text.trim().isEmpty
      ? null
      : platilloPrecioCtrl.text.trim(),
  'imagen': imagenUrl,
});

    platilloNombreCtrl.clear();
    platilloPrecioCtrl.clear();
    platilloImagen = null;
  });
}
void editarPlatillo(int index) {
  final p = platillos[index];

  platilloNombreCtrl.text = p['nombre'] ?? '';
  platilloPrecioCtrl.text =
      p['precio'] != null ? p['precio'].toString() : '';

  setState(() {
    platillos.removeAt(index);
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Edita el platillo y vuelve a agregarlo'),
    ),
  );
}

Future<void> eliminarLogo() async {
  final storage =
      Supabase.instance.client.storage.from('hoteles_cabanas');

  if (widget.lugar['logo'] == null) return;

  final uri = Uri.parse(widget.lugar['logo']);
  final path = uri.pathSegments
      .skipWhile((e) => e != 'hoteles_cabanas')
      .skip(1)
      .join('/');

  await storage.remove([path]);

  setState(() {
    widget.lugar['logo'] = null;
  });
}

  Future<void> actualizar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      String? imagenPrincipalUrl = widget.lugar['imagen_principal'];
      String? logoUrl = widget.lugar['logo'];

     if (nuevaImagenPrincipal != null) {
  imagenPrincipalUrl =
      await uploadImagenPrincipal(nuevaImagenPrincipal!);
}

    
    if (nuevoLogo != null) {
  logoUrl = await uploadLogo(nuevoLogo!);
}

      await Supabase.instance.client
          .from('lugares')
          .update({
            'nombre': nombreCtrl.text.trim(),
            'descripcion': descripcionCtrl.text.trim(),
            'precio': precioCtrl.text.trim().isEmpty
    ? null
    : precioCtrl.text.trim(),
            'telefono': telefonoCtrl.text.trim(),
            'pagina_web': webCtrl.text.trim(),
            'facebook': facebookCtrl.text.trim(),
            'latitud': latCtrl.text.isNotEmpty
                ? double.parse(latCtrl.text)
                : null,
            'longitud': lngCtrl.text.isNotEmpty
                ? double.parse(lngCtrl.text)
                : null,
            'tipo': tipoSeleccionado,
            'imagen_principal': imagenPrincipalUrl,
            'logo': logoUrl,
            'galeria': galeriaExistente,
            'videos': videosExistentes,
            'servicios': servicios,
            'actividades': actividades,
            'recamaras': recamaras,
            'platillos': platillos,
          })
          .eq('id', widget.lugar['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Actualizado correctamente')),
);

// 👇 CAMBIO AQUÍ
Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickImagenPrincipal() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => nuevaImagenPrincipal = File(image.path));
    }
  }

  Future<void> pickLogo() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => nuevoLogo = File(image.path));
    }
  }

  Widget _buildYoutubeThumbnail(String url) {
  final videoId = obtenerYoutubeId(url);

  if (videoId == null) {
    return const SizedBox(
      width: 160,
      height: 100,
      child: Center(
        child: Icon(Icons.videocam),
      ),
    );
  }

  return Container(
    width: 160,
    height: 100,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      image: DecorationImage(
        image: NetworkImage(
          'https://img.youtube.com/vi/$videoId/0.jpg',
        ),
        fit: BoxFit.cover,
      ),
    ),
    child: const Center(
      child: Icon(
        Icons.play_circle_fill,
        color: Colors.white,
        size: 40,
      ),
    ),
  );
}
Widget _campoEditable(
  TextEditingController ctrl,
  String label, {
  required IconData icono,
  TextInputType tipo = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    ctrl.clear();
                  });
                },
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar lugar')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
  if (v == null || v.trim().isEmpty) {
    return 'Campo obligatorio';
  }
  return null;
},
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: precioCtrl,
              decoration: const InputDecoration(
                labelText: 'Precio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Imagen principal'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: pickImagenPrincipal,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: nuevaImagenPrincipal != null
                    ? Image.file(nuevaImagenPrincipal!)
                    : widget.lugar['imagen_principal'] != null
                        ? Image.network(
  "${widget.lugar['imagen_principal']}?t=${DateTime.now().millisecondsSinceEpoch}",
  fit: BoxFit.cover,
)
                        : const Center(
                            child: Icon(Icons.add_a_photo),
                          ),
              ),
            ),

            const SizedBox(height: 30),
            const SizedBox(height: 30),
const Text('Logo'),
const SizedBox(height: 8),

GestureDetector(
  onTap: pickLogo,
  child: Container(
    height: 120,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
    ),
    child: nuevoLogo != null
        ? Image.file(nuevoLogo!)
        : widget.lugar['logo'] != null
            ? Image.network(widget.lugar['logo'])
            : const Center(
                child: Icon(Icons.add_photo_alternate),
              ),
  ),
),

if (widget.lugar['logo'] != null)
  TextButton.icon(
    onPressed: eliminarLogo,
    icon: const Icon(Icons.delete, color: Colors.red),
    label: const Text(
      'Eliminar logo',
      style: TextStyle(color: Colors.red),
    ),
  ),

            const SizedBox(height: 20),
const Text('Galería'),

TextButton.icon(
  onPressed: agregarImagenGaleria,
  icon: const Icon(Icons.add),
  label: const Text('Agregar imágenes'),
),

Wrap(
  spacing: 8,
  runSpacing: 8,
  children: galeriaExistente.map((url) {
    return Stack(
      children: [
        Image.network(
          url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                galeriaExistente.remove(url);
              });
            },
            child: Container(
              color: Colors.black54,
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }).toList(),
),

const SizedBox(height: 20),

const SizedBox(height: 25),
const Text('Videos'),

Wrap(
  spacing: 12,
  runSpacing: 12,
  children: videosExistentes.map((url) {
    final isYoutube =
        url.contains('youtube.com') || url.contains('youtu.be');

    return Stack(
      children: [
        isYoutube
            ? _buildYoutubeThumbnail(url)
            : VideoThumbnailWidget(url: url),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                videosExistentes.remove(url);
              });
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }).toList(),
),

const SizedBox(height: 10),

TextButton.icon(
  onPressed: agregarVideoDesdeTelefono,
  icon: const Icon(Icons.video_library),
  label: const Text('Subir video desde el teléfono'),
),

const Text('Servicios'),

Wrap(
  spacing: 8,
  children: servicios.map((s) {
    return Chip(
      label: Text(s),
      onDeleted: () {
        setState(() {
          servicios.remove(s);
        });
      },
    );
  }).toList(),
),
TextFormField(
  controller: servicioCtrl,
  decoration: InputDecoration(
    labelText: 'Nuevo servicio',
    suffixIcon: IconButton(
      icon: const Icon(Icons.add),
      onPressed: () {
        if (servicioCtrl.text.trim().isEmpty) return;

        setState(() {
          servicios.add(servicioCtrl.text.trim());
          servicioCtrl.clear();
        });
      },
    ),
    border: const OutlineInputBorder(),
  ),
),

const SizedBox(height: 30),

const Text('Actividades'),

Wrap(
  spacing: 8,
  children: actividades.map((a) {
    return Chip(
      label: Text(a),
      onDeleted: () {
        setState(() {
          actividades.remove(a);
        });
      },
    );
  }).toList(),
),

TextFormField(
  controller: actividadCtrl,
  decoration: InputDecoration(
    labelText: 'Nueva actividad',
    suffixIcon: IconButton(
      icon: const Icon(Icons.add),
      onPressed: () {
        if (actividadCtrl.text.trim().isEmpty) return;

        setState(() {
          actividades.add(actividadCtrl.text.trim());
          actividadCtrl.clear();
        });
      },
    ),
    border: const OutlineInputBorder(),
  ),
),

const SizedBox(height: 30),
const Text('Recámaras'),

const SizedBox(height: 10),

TextFormField(
  controller: recamaraNombreCtrl,
  decoration: const InputDecoration(
    labelText: 'Tipo de recámara (Ej: Doble, Suite)',
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 10),

TextFormField(
  controller: recamaraPrecioCtrl,
  decoration: const InputDecoration(
    labelText: 'Precio (opcional)',
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 10),

TextButton.icon(
  onPressed: pickImagenRecamara,
  icon: const Icon(Icons.image),
  label: const Text('Agregar imagen'),
),

const SizedBox(height: 10),

ElevatedButton(
  onPressed: agregarRecamara,
  child: const Text('Agregar recámara'),
),

const SizedBox(height: 20),

Wrap(
  spacing: 12,
  runSpacing: 12,
  children: recamaras.map((r) {
    return SizedBox(
      width: 170,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (r['imagen'] != null)
  ClipRRect(
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(12),
    ),
    child: r['imagen'].toString().startsWith('http')
        ? Image.network(
            r['imagen'],
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : Image.file(
            File(r['imagen']),
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
  ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    r['nombre'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (r['precio'] != null &&
    r['precio'].toString().trim().isNotEmpty)
  Text('\$${r['precio']}'),

                  const SizedBox(height: 6),

                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      setState(() {
                        recamaras.remove(r);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }).toList(),
),
const SizedBox(height: 30),
const Text('Platillos'),

const SizedBox(height: 10),

TextFormField(
  controller: platilloNombreCtrl,
  decoration: const InputDecoration(
    labelText: 'Nombre del platillo',
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 10),

TextFormField(
  controller: platilloPrecioCtrl,
  decoration: const InputDecoration(
    labelText: 'Precio',
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 10),

TextButton.icon(
  onPressed: pickImagenPlatillo,
  icon: const Icon(Icons.image),
  label: const Text('Agregar imagen'),
),

const SizedBox(height: 10),
if (platilloImagen != null)
  Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Image.file(
      platilloImagen!,
      height: 80,
      width: 50,
      fit: BoxFit.cover,
    ),
  ),

ElevatedButton(
  onPressed: agregarPlatillo,
  child: const Text('Agregar platillo'),
),

const SizedBox(height: 20),


Wrap(
  spacing: 12,
  runSpacing: 12,
  children: platillos.asMap().entries.map((entry) {
    final index = entry.key;
    final p = entry.value;

    return SizedBox(
      width: 170,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (p['imagen'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: p['imagen'].toString().startsWith('http')
                    ? Image.network(
                        p['imagen'],
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(p['imagen']),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    p['nombre'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (p['precio'] != null &&
    p['precio'].toString().trim().isNotEmpty)
  Text('\$${p['precio']}'),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          editarPlatillo(index);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            platillos.removeAt(index);
                          });
                        },
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
  }).toList(),
),
const SizedBox(height: 30),
const Text(
  'Datos de contacto',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),

const SizedBox(height: 10),

_campoEditable(
  telefonoCtrl,
  'Teléfono',
  icono: Icons.phone,
  tipo: TextInputType.phone,
),

_campoEditable(
  webCtrl,
  'Página web',
  icono: Icons.language,
  tipo: TextInputType.url,
),

_campoEditable(
  facebookCtrl,
  'Facebook',
  icono: Icons.facebook,
  tipo: TextInputType.url,
),

const SizedBox(height: 30),

const Text(
  'Ubicación',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),

const SizedBox(height: 10),

Row(
  children: [
    Expanded(
      child: _campoEditable(
        latCtrl,
        'Latitud',
        icono: Icons.map,
        tipo: TextInputType.number,
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _campoEditable(
        lngCtrl,
        'Longitud',
        icono: Icons.map_outlined,
        tipo: TextInputType.number,
      ),
    ),
  ],
),
            ElevatedButton(
              onPressed: loading ? null : actualizar,
              child: loading
                  ? const CircularProgressIndicator(
                      color: Colors.white)
                  : const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}


/// PARA QUE LOS VIDEOS SE VISUALICEN EN MINIATURA
class VideoThumbnailWidget extends StatefulWidget {
  final String url;

  const VideoThumbnailWidget({super.key, required this.url});

  @override
  State<VideoThumbnailWidget> createState() =>
      _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState
    extends State<VideoThumbnailWidget> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller =
        VideoPlayerController.network(widget.url)
          ..initialize().then((_) {
            setState(() {});
          });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox(
        width: 160,
        height: 100,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      width: 160,
      height: 100,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: VideoPlayer(controller),
          ),
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}