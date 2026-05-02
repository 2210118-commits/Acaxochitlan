import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';

/// =========================
/// MODELO
/// =========================
class TiendaHidarte {
  final String nombre;
  final String descripcion;
  final String categoria;
  final int? stock;
  final String imagenPrincipal;
  final List<Map<String, dynamic>> galeria;
  final List<String> videos;
  final List<Map<String, dynamic>> productos;

  // 🔥 NUEVO
  final String? paginaWeb;
  final String? facebook;
  final String? telefono;
  final String? comoLlegar;
  final double? latitud;
  final double? longitud;

  TiendaHidarte({
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    this.stock,
    required this.imagenPrincipal,
    required this.galeria,
    required this.videos,
    required this.productos,

    // 🔥 NUEVO
    this.paginaWeb,
    this.facebook,
    this.telefono,
    this.comoLlegar,
    this.latitud,
    this.longitud,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'stock': stock,
      'imagen_principal': imagenPrincipal,
      'galeria': galeria,
      'videos': videos,
      'productos': productos,

      // 🔥 NUEVO
      'pagina_web': paginaWeb,
      'facebook': facebook,
      'telefono': telefono,
      'latitud': latitud,
      'longitud': longitud,
    };
  }
}

/// =========================
/// SERVICIO
/// =========================
class TiendaService {
  final storage = Supabase.instance.client.storage.from('tienda_hidarte');
  final db = Supabase.instance.client.from('tienda_hidarte');
  final uuid = const Uuid();

  String normalizarNombre(String nombre) {
    return nombre.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  Future<String> uploadFile(File file, String folder, String nombre) async {
    final carpeta = normalizarNombre(nombre);
    final ext = file.path.split('.').last;
    final path = '$carpeta/$folder/${uuid.v4()}.$ext';

    await storage.upload(path, file);
    return storage.getPublicUrl(path);
  }

  Future<void> insertarTienda(Map<String, dynamic> data) async {
    await db.insert(data);
  }
}

/// =========================
/// PAGE
/// =========================
class SubirTiendaHidartePage extends StatefulWidget {
  const SubirTiendaHidartePage({super.key});

  @override
  State<SubirTiendaHidartePage> createState() =>
      _SubirTiendaHidartePageState();
}


class _SubirTiendaHidartePageState
    extends State<SubirTiendaHidartePage> {
  final _formKey = GlobalKey<FormState>();

  /// CONTROLLERS
  final nombreCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final categoriaCtrl = TextEditingController();
  final stockCtrl = TextEditingController();

  final webCtrl = TextEditingController();
  final facebookCtrl = TextEditingController();
  final comoLlegarCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();

  final productoNombreCtrl = TextEditingController();
  final productoDescCtrl = TextEditingController();
  final productoPrecioCtrl = TextEditingController();

  /// FILES
  File? imagenPrincipal;
  File? productoImagen;

  final List<File> galeria = [];
  final List<TextEditingController> descripcionesGaleria = [];
  final List<File> videos = [];
  final List<Map<String, dynamic>> productos = [];

  final picker = ImagePicker();

  bool loading = false;

  String? _nullSiVacio(String text) {
  final t = text.trim();
  return t.isEmpty ? null : t;
}

  /// =========================
  /// PICKERS
  /// =========================

  Future<void> pickImagenPrincipal() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => imagenPrincipal = File(img.path));
    }
  }

  Future<void> pickGaleria() async {
    final imgs = await picker.pickMultiImage();
    if (imgs.isNotEmpty) {
      setState(() {
        for (var i in imgs) {
          galeria.add(File(i.path));
          descripcionesGaleria.add(TextEditingController());
        }
      });
    }
  }

  Future<void> pickVideo() async {
    final vid = await picker.pickVideo(source: ImageSource.gallery);
    if (vid != null) {
      setState(() => videos.add(File(vid.path)));
    }
  }

  Future<void> pickProductoImagen() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => productoImagen = File(img.path));
    }
  }

  /// =========================
  /// HELPERS
  /// =========================

  void _mostrar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// =========================
  /// SUB FUNCIONES
  /// =========================

  Future<List<Map<String, dynamic>>> _subirGaleria(
      TiendaService service, String nombre) async {
    final List<Map<String, dynamic>> data = [];

    for (int i = 0; i < galeria.length; i++) {
      final url = await service.uploadFile(galeria[i], 'galeria', nombre);

      data.add({
        'url': url,
        'descripcion': descripcionesGaleria[i].text,
      });
    }

    return data;
  }

  Future<Uint8List?> _getThumbnail(File file) async {
  try {
    return await VideoThumbnail.thumbnailData(
      video: file.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 300,
      quality: 75,
    );
  } catch (e) {
    return null;
  }
}

  Future<List<String>> _subirVideos(
      TiendaService service, String nombre) async {
    final List<String> data = [];

    for (final v in videos) {
      final url = await service.uploadFile(v, 'videos', nombre);
      data.add(url);
    }

    return data;
  }

  List<Map<String, dynamic>> _mapProductos() {
    return productos.map((p) {
      return {
        'nombre': p['nombre'],
        'descripcion': p['descripcion'],
        'precio': p['precio'],
        'imagen': p['imagen'],
      };
    }).toList();
  }

  /// =========================
  /// SUBIR
  /// =========================

  Future<void> subir() async {
  if (imagenPrincipal == null) {
    _mostrar('Imagen principal obligatoria');
    return;
  }

  if (!_formKey.currentState!.validate()) return;

  setState(() => loading = true);

  try {
    final service = TiendaService();
    final nombre = nombreCtrl.text.trim();

    // 🔥 VALIDAR LAT / LNG
    double? lat = double.tryParse(latCtrl.text);
    double? lng = double.tryParse(lngCtrl.text);

    if ((latCtrl.text.isNotEmpty && lat == null) ||
        (lngCtrl.text.isNotEmpty && lng == null)) {
      _mostrar('Latitud o longitud inválida');
      setState(() => loading = false);
      return;
    }

    final imagenUrl =
        await service.uploadFile(imagenPrincipal!, 'principal', nombre);

    final galeriaData = await _subirGaleria(service, nombre);
    final videosData = await _subirVideos(service, nombre);
    final productosData = _mapProductos();

    final tienda = TiendaHidarte(
      nombre: nombre,
      descripcion: descripcionCtrl.text.trim(),
      categoria: categoriaCtrl.text.trim(),
      stock: int.tryParse(stockCtrl.text),
      imagenPrincipal: imagenUrl,
      galeria: galeriaData,
      videos: videosData,
      productos: productosData,

      // 🔥 CORREGIDO
      paginaWeb: _nullSiVacio(webCtrl.text),
      facebook: _nullSiVacio(facebookCtrl.text),
      telefono: _nullSiVacio(telefonoCtrl.text),
      comoLlegar: _nullSiVacio(comoLlegarCtrl.text),
      latitud: lat,
      longitud: lng,
    );

    await service.insertarTienda(tienda.toJson());

    _mostrar('Producto subido correctamente');

    Navigator.pop(context, true); // 🔥 mejorado

  } catch (e) {
    _mostrar('Error: $e');
  } finally {
    setState(() => loading = false);
  }
}

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir Tienda Hidarte')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _campo(nombreCtrl, 'Nombre', obligatorio: true),
            _campo(descripcionCtrl, 'Descripción', max: 3),
            _campo(categoriaCtrl, 'Categoría'),
            _campo(stockCtrl, 'Stock', tipo: TextInputType.number),

            _imagenPicker(
              titulo: 'Imagen principal *',
              file: imagenPrincipal,
              onTap: pickImagenPrincipal,
            ),

            _galeriaPicker(),
            _videoPicker(),

            const SizedBox(height: 20),

            const Text("Productos"),
            _campo(productoNombreCtrl, 'Nombre producto'),
            _campo(productoDescCtrl, 'Descripción'),
            _campo(productoPrecioCtrl, 'Precio'),

            _imagenPicker(
              titulo: 'Imagen producto',
              file: productoImagen,
              onTap: pickProductoImagen,
            ),

            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty) {
                  _mostrar('Primero agrega el nombre del negocio');
                  return;
                }

                if (productoNombreCtrl.text.isEmpty) return;

                final service = TiendaService();
                String? imgUrl;

                if (productoImagen != null) {
                  imgUrl = await service.uploadFile(
                      productoImagen!, 'productos', nombreCtrl.text);
                }

                setState(() {
                  productos.add({
                    'nombre': productoNombreCtrl.text,
                    'descripcion': productoDescCtrl.text,
                    'precio':
                        double.tryParse(productoPrecioCtrl.text),
                    'imagen': imgUrl,
                  });

                  productoNombreCtrl.clear();
                  productoDescCtrl.clear();
                  productoPrecioCtrl.clear();
                  productoImagen = null;
                });
              },
              child: const Text('Agregar producto'),
            ),

            const SizedBox(height: 20),

const Text(
  "Contacto",
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),

_campo(webCtrl, 'Página web'),
_campo(facebookCtrl, 'Facebook'),
_campo(telefonoCtrl, 'Teléfono', tipo: TextInputType.phone),

const SizedBox(height: 20),

const Text(
  "Ubicación",
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),


_campo(latCtrl, 'Latitud', tipo: TextInputType.number),
_campo(lngCtrl, 'Longitud', tipo: TextInputType.number),

            ElevatedButton(
              onPressed: loading ? null : subir,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Subir'),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// COMPONENTES
  /// =========================

  Widget _campo(TextEditingController ctrl, String label,
      {bool obligatorio = false,
      int max = 1,
      TextInputType tipo = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        maxLines: max,
        keyboardType: tipo,
        validator:
            obligatorio ? (v) => v!.isEmpty ? 'Campo obligatorio' : null : null,
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
        Text(titulo),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: file != null
                ? Image.file(file, fit: BoxFit.cover)
                : const Center(child: Icon(Icons.add_a_photo)),
          ),
        ),
      ],
    );
  }

  Widget _galeriaPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Galería'),
        Column(
          children: List.generate(galeria.length, (i) {
            return Column(
              children: [
                Image.file(galeria[i], width: 100),
                TextField(
                  controller: descripcionesGaleria[i],
                  decoration:
                      const InputDecoration(labelText: 'Descripción'),
                ),
              ],
            );
          }),
        ),
        TextButton(onPressed: pickGaleria, child: const Text('Agregar')),
      ],
    );
  }

  Widget _videoPicker() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Videos'),

      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(videos.length, (i) {
          final file = videos[i];

          return FutureBuilder<Uint8List?>(
            future: _getThumbnail(file),
            builder: (context, snapshot) {
              Widget content;

              if (snapshot.connectionState == ConnectionState.waiting) {
                content = Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasData) {
                content = Stack(
                  children: [
                    Image.memory(
                      snapshot.data!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),

                    /// OSCURECER
                    Container(
                      width: 120,
                      height: 120,
                      color: Colors.black.withOpacity(0.3),
                    ),

                    /// ICONO PLAY
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
                );
              } else {
                content = Container(
                  width: 120,
                  height: 120,
                  color: Colors.black12,
                  child: const Icon(Icons.videocam),
                );
              }

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: content,
                  ),

                  /// ❌ ELIMINAR VIDEO
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          videos.removeAt(i);
                        });
                      },
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ),

      TextButton(
        onPressed: pickVideo,
        child: const Text('Agregar'),
      ),
    ],
  );
}
}