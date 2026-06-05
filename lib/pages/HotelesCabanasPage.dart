import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';


class HotelesCabanasPage extends StatefulWidget {
  const HotelesCabanasPage({super.key});

  @override
  State<HotelesCabanasPage> createState() => _HotelesCabanasPageState();
}

class _HotelesCabanasPageState extends State<HotelesCabanasPage> {
  // =========================
  // FORM
  // =========================
  final _formKey = GlobalKey<FormState>();

  // =========================
  // CONTROLLERS
  // =========================
  final nombreCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final precioCtrl = TextEditingController();
  final recamaraNombreCtrl = TextEditingController();
  final recamaraPrecioCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();

  final servicioCtrl = TextEditingController();
  final platilloCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
final webCtrl = TextEditingController();
final facebookCtrl = TextEditingController();
final actividadCtrl = TextEditingController();
final platilloNombreCtrl = TextEditingController();
final platilloPrecioCtrl = TextEditingController();
final whatsappCtrl = TextEditingController();
final horarioCtrl = TextEditingController();



  // =========================
  // ESTADO
  // =========================
  String tipoSeleccionado = 'hotel';
  bool loading = false;
  bool cargandoPlatillo = false;
  bool cargandoRecamara = false;
  bool cargandoVideo = false;

  File? recamaraImagen;
  File? videoFile;
  File? imagenPrincipal;
  File? platilloImagen;
  File? logo;

  Uint8List? videoThumbnail;


  final List<File> galeria = [];
  final List<Map<String, dynamic>> videos = [];
  final List<String> servicios = [];
  final List<Map<String, dynamic>> platillos = [];
  final List<String> actividades = [];
  final List<Map<String, dynamic>> recamaras = [];



  final picker = ImagePicker();
  final uuid = const Uuid();

  // =========================
  // PICKERS
  // =========================
  Future<void> pickRecamaraImagen() async {
  final image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    setState(() => recamaraImagen = File(image.path));
  }
}

  Future<void> pickImagenPrincipal() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => imagenPrincipal = File(image.path));
    }
  }

  Future<void> pickVideo() async {
  final video = await picker.pickVideo(source: ImageSource.gallery);

  if (video != null) {
    final file = File(video.path);

    final uint8list = await VideoThumbnail.thumbnailData(
      video: file.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 300,
      quality: 75,
    );

    setState(() {
      videoFile = file;
      videoThumbnail = uint8list;
    });
  }
}



  Future<void> pickLogo() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => logo = File(image.path));
    }
  }

  Future<void> pickGaleria() async {
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        galeria.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  Future<void> pickPlatilloImagen() async {
  final image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    setState(() => platilloImagen = File(image.path));
  }
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

  // =========================
  // UPLOAD
  // =========================

  Future<String> uploadFile(
  File file,
  String folder,
  String nombreLugar,
) async {
  final carpetaLugar = normalizarNombre(nombreLugar);
  final extension = file.path.split('.').last;

  final storage =
      Supabase.instance.client.storage.from('hoteles_cabanas');

  final basePath = '$carpetaLugar/$folder';

  String filePath;

  // 🔥 SOLO numerar para principal
  if (folder == 'principal') {
    final existentes = await storage.list(path: basePath);

    int numero = 1;

    for (var archivo in existentes) {
      final nombre = archivo.name; // principal1.jpg

      if (nombre.startsWith('principal')) {
        final sinExtension = nombre.split('.').first;
        final n = int.tryParse(
            sinExtension.replaceAll('principal', ''));

        if (n != null && n >= numero) {
          numero = n + 1;
        }
      }
    }

    filePath = '$basePath/principal$numero.$extension';
  } else {
    // lo demás sigue normal con uuid
    filePath = '$basePath/${uuid.v4()}.$extension';
  }

  await storage.upload(filePath, file);

  return storage.getPublicUrl(filePath);
}


  // =========================
  // GUARDAR
  // =========================

  Future<void> subir() async {
  if (imagenPrincipal == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La imagen principal es obligatoria')),
    );
    return;
  }

  if (!_formKey.currentState!.validate()) return;

  setState(() => loading = true);

  // ✅ DECLARAR AQUÍ (ANTES DE USARLO)
  final nombreLugar = nombreCtrl.text.trim();

  try {
    final imagenPrincipalUrl =
        await uploadFile(imagenPrincipal!, 'principal', nombreLugar);

    final logoUrl = logo != null
        ? await uploadFile(logo!, 'logos', nombreLugar)
        : null;

    final List<String> galeriaUrls = [];
    for (final img in galeria) {
      galeriaUrls.add(
        await uploadFile(img, 'galeria', nombreLugar),
      );
    }

    await Supabase.instance.client.from('lugares').insert({
      'nombre': nombreLugar,
      'tipo': tipoSeleccionado,
      'descripcion': descripcionCtrl.text.trim(),
      'precio': precioCtrl.text.isNotEmpty
    ? precioCtrl.text.trim()
    : null,
      'imagen_principal': imagenPrincipalUrl,
      'logo': logoUrl,
      'galeria': galeriaUrls,
      'servicios': servicios,
      'actividades': actividades,
      'recamaras': recamaras,
      'platillos': platillos,
      'videos': videos.map((v) => v['url']).toList(),
      'latitud': latCtrl.text.isNotEmpty
          ? double.parse(latCtrl.text)
          : null,
      'longitud': lngCtrl.text.isNotEmpty
          ? double.parse(lngCtrl.text)
          : null,
      'telefono': telefonoCtrl.text.trim(),
      'pagina_web': webCtrl.text.trim(),
      'facebook': facebookCtrl.text.trim(),
      'whatsapp': whatsappCtrl.text.trim(),
      'horario': horarioCtrl.text.trim(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subido correctamente')),
    );

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    if (mounted) setState(() => loading = false);
  }
}


  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoteles y Cabañas')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _seccionTitulo('Información básica'),

            _dropdownTipo(),
            _campo(nombreCtrl, 'Nombre', obligatorio: true),
            _campo(descripcionCtrl, 'Descripción', max: 4),

            _seccionTitulo('Imágenes'),
            _imagenPicker(
              titulo: 'Imagen principal *',
              file: imagenPrincipal,
              onTap: pickImagenPrincipal,
            ),
            _imagenPicker(
              titulo: 'Logotipo',
              file: logo,
              onTap: pickLogo,
            ),
            _galeriaPicker(),

            _seccionTitulo('Servicios y detalles'),
            _listaEditable(
              ctrl: servicioCtrl,
              lista: servicios,
              label: 'Servicio',
            ),
            _seccionTitulo('Videos'),

GestureDetector(
  onTap: pickVideo,
  child: Container(
    height: 200,
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(12),
      color: Colors.black12,
    ),
    child: videoThumbnail != null
        ? Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                videoThumbnail!,
                fit: BoxFit.cover,
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ],
          )
        : const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 40),
                SizedBox(height: 8),
                Text('Seleccionar video'),
              ],
            ),
          ),
  ),
),

const SizedBox(height: 10),

if (videoFile != null)
  ElevatedButton(
    onPressed: cargandoVideo
        ? null
        : () async {
            if (nombreCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Escribe primero el nombre del lugar'),
                ),
              );
              return;
            }

            setState(() => cargandoVideo = true);

            try {
              final videoUrl = await uploadFile(
                videoFile!,
                'videos',
                nombreCtrl.text.trim(),
              );

              setState(() {
                videos.add({
                'url': videoUrl,
                'thumbnail': videoThumbnail,});
                videoFile = null;
                videoThumbnail = null;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video agregado')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            } finally {
              if (mounted) {
                setState(() => cargandoVideo = false);
              }
            }
          },
    child: cargandoVideo
        ? const CircularProgressIndicator(color: Colors.white)
        : const Text('Agregar video'),
  ),

const SizedBox(height: 15),

Wrap(
  spacing: 8,
  runSpacing: 8,
  children: videos.map((video) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Column(
          children: [
            if (video['thumbnail'] != null)
              Stack(
                children: [
                  Image.memory(
                    video['thumbnail'],
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text(
                    'Video agregado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => videos.remove(video));
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }).toList(),
),



            _seccionTitulo('Tipos de recámaras'),

_campo(recamaraNombreCtrl, 'Nombre de la recámara'),
_campo(recamaraPrecioCtrl,'Precio (opcional)'),


_imagenPicker(
  titulo: 'Imagen de la recámara',
  file: recamaraImagen,
  onTap: pickRecamaraImagen,
),
//BOTON PARA AGREGAR RECAMARA CON BOTON
ElevatedButton(
  onPressed: cargandoRecamara
      ? null
      : () async {
          if (recamaraNombreCtrl.text.isEmpty &&
              recamaraImagen == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Agrega al menos nombre o imagen'),
              ),
            );
            return;
          }

          setState(() => cargandoRecamara = true);

          try {
            String? imagenUrl;

            if (recamaraImagen != null) {
              imagenUrl = await uploadFile(
                recamaraImagen!,
                'recamaras',
                nombreCtrl.text.trim(),
              );
            }

            setState(() {
              recamaras.add({
                if (recamaraNombreCtrl.text.isNotEmpty)
                  'nombre': recamaraNombreCtrl.text.trim(),

                if (recamaraPrecioCtrl.text.isNotEmpty)
                  'precio': recamaraPrecioCtrl.text.trim(),

                if (imagenUrl != null)
                  'imagen': imagenUrl,
              });

              recamaraNombreCtrl.clear();
              recamaraPrecioCtrl.clear();
              recamaraImagen = null;
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al subir recámara: $e')),
            );
          } finally {
            if (mounted) {
              setState(() => cargandoRecamara = false);
            }
          }
        },
  child: cargandoRecamara
      ? const CircularProgressIndicator(color: Colors.white)
      : const Text('Agregar recámara'),
),
//MOSTRAR LAS RECAMARAS O HABITACIONES AGREGADAS
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: recamaras.map((r) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Column(
          children: [
            if (r['imagen'] != null)
              Image.network(
                r['imagen'],
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                r['nombre'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (r['precio'] != null)
                    Text('\$${r['precio']}'),
          ],
        ),
      ),
    );
  }).toList(),
),


                _campo(recamaraPrecioCtrl,'Precio general (opcional)'),
                _seccionTitulo('Actividades disponibles'),

_listaEditable(
  ctrl: actividadCtrl,
  lista: actividades,
  label: 'Actividad (ej. Senderismo, Fogata, Kayak)',
),

            _seccionTitulo('Comida / Platillos'),

_campo(platilloNombreCtrl, 'Nombre del platillo'),
_campo(
  platilloPrecioCtrl,
  'Precio',
  tipo: TextInputType.number,
),

_imagenPicker(
  titulo: 'Foto del platillo',
  file: platilloImagen,
  onTap: pickPlatilloImagen,
),

ElevatedButton(
  onPressed: cargandoPlatillo
      ? null
      : () async {
          if (
              platilloNombreCtrl.text.isEmpty &&
              platilloPrecioCtrl.text.isEmpty &&
              platilloImagen == null
          ) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Agrega al menos nombre, precio o imagen'),
              ),
            );
            return;
          }

          setState(() => cargandoPlatillo = true);

          try {
            String? imagenUrl;

if (platilloImagen != null) {
  imagenUrl = await uploadFile(
    platilloImagen!,
    'platillos',
    nombreCtrl.text.trim(),
  );
}



            setState(() {
              platillos.add({
                if (platilloNombreCtrl.text.isNotEmpty)
                  'nombre': platilloNombreCtrl.text.trim(),

                if (platilloPrecioCtrl.text.isNotEmpty)
                  'precio': double.parse(platilloPrecioCtrl.text),

                if (imagenUrl != null)
                  'imagen': imagenUrl,
              });

              platilloNombreCtrl.clear();
              platilloPrecioCtrl.clear();
              platilloImagen = null;
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al subir platillo: $e')),
            );
          } finally {
            if (mounted) {
              setState(() => cargandoPlatillo = false);
            }
          }
        },
  child: cargandoPlatillo
      ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add),
            SizedBox(width: 8),
            Text('Agregar platillo'),
          ],
        ),
),


Wrap(
  spacing: 8,
  runSpacing: 8,
  children: platillos.map((p) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Column(
          children: [
            if (p['imagen'] != null)
              Image.network(
                p['imagen'],
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  if (p['nombre'] != null)
                    Text(
                      p['nombre'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                  if (p['precio'] != null)
                    Text('\$${p['precio']}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }).toList(),
),

            _seccionTitulo('Datos de contacto'),

_campo(
  telefonoCtrl,
  'Teléfono',
  tipo: TextInputType.phone,
),

_campo(
  webCtrl,
  'Página web',
  tipo: TextInputType.url,
),

_campo(
  whatsappCtrl,
  'WhatsApp',
  tipo: TextInputType.phone,
),

_campo(
  facebookCtrl,
  'Facebook (URL o nombre)',
  tipo: TextInputType.url,
),

_campo(
  horarioCtrl,
  'Horario',
),


            _seccionTitulo('Ubicación'),
            _campo(latCtrl, 'Latitud', tipo: TextInputType.number),
            _campo(lngCtrl, 'Longitud', tipo: TextInputType.number),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: loading ? null : subir,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Subir hoteles_cabañas o lugarTuristico'),
            ),
          ],
        ),
      ),
    );
  }
  // =========================
  // COMPONENTES
  // =========================

  Widget _seccionTitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _dropdownTipo() {
    return DropdownButtonFormField<String>(
      value: tipoSeleccionado,
      items: const [
        DropdownMenuItem(value: 'hotel', child: Text('Hotel')),
        DropdownMenuItem(value: 'cabana', child: Text('Cabaña')),
        DropdownMenuItem(value: 'lugar_turistico', child: Text('Lugar turístico')),
        DropdownMenuItem(value: 'restaurante', child: Text('Restaurante')), 
      ],
      onChanged: (v) => setState(() => tipoSeleccionado = v!),
      decoration: const InputDecoration(
        labelText: 'Tipo',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String label, {
    bool obligatorio = false,
    int max = 1,
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        maxLines: max,
        keyboardType: tipo,
        validator: obligatorio
            ? (v) => v!.isEmpty ? 'Campo obligatorio' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _imagenPicker({
  required String titulo,
  required File? file,
  required VoidCallback onTap,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),

      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 200, // 🔒 tamaño fijo
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: file != null
              ? Center(
                  child: Image.file(
                    file,
                    fit: BoxFit.contain, // ✅ IMAGEN ORIGINAL
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 40),
                      SizedBox(height: 8),
                      Text('Seleccionar imagen'),
                    ],
                  ),
                ),
        ),
      ),

      const SizedBox(height: 15),
    ],
  );
}


  Widget _galeriaPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Galería'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: galeria
              .map((e) => Image.file(e, width: 80, height: 80))
              .toList(),
        ),
        TextButton.icon(
          onPressed: pickGaleria,
          icon: const Icon(Icons.photo_library),
          label: const Text('Agregar imágenes'),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _listaEditable({
    required TextEditingController ctrl,
    required List<String> lista,
    required String label,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  setState(() {
                    lista.add(ctrl.text.trim());
                    ctrl.clear();
                  });
                }
              },
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: lista
              .map(
                (e) => Chip(
                  label: Text(e),
                  onDeleted: () => setState(() => lista.remove(e)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
