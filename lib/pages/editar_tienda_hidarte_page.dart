import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../widgets/video_player_widget.dart';

class EditarTiendaHidartePage extends StatefulWidget {
  final Map<String, dynamic> producto;

  const EditarTiendaHidartePage({super.key, required this.producto});

  @override
  State<EditarTiendaHidartePage> createState() =>
      _EditarTiendaHidartePageState();
}

class _EditarTiendaHidartePageState
    extends State<EditarTiendaHidartePage> {
  final picker = ImagePicker();
  final uuid = const Uuid();

  final db = Supabase.instance.client.from('tienda_hidarte');
  final storage =
      Supabase.instance.client.storage.from('tienda_hidarte');

  /// CONTROLLERS
  late TextEditingController nombreCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController precioCtrl;
late TextEditingController categoriaCtrl;
late TextEditingController stockCtrl;
late TextEditingController webCtrl;
late TextEditingController facebookCtrl;
late TextEditingController telefonoCtrl;
late TextEditingController latCtrl;
late TextEditingController lngCtrl;

  /// MAPA
  double? lat;
  double? lng;

  /// IMAGEN PRINCIPAL
  File? nuevaImagenPrincipal;

  /// GALERÍA
  List<Map<String, dynamic>> galeria = [];
  List<File> nuevasGaleria = [];
  List<String> descripcionNuevas = [];

  /// VIDEOS
  List<dynamic> videos = [];
  List<File> nuevosVideos = [];

  /// PRODUCTOS
  List<Map<String, dynamic>> productos = [];

  bool loading = false;

  @override
void initState() {
  super.initState();

  nombreCtrl = TextEditingController(text: widget.producto['nombre']);
  descripcionCtrl = TextEditingController(text: widget.producto['descripcion']);

  precioCtrl = TextEditingController(
    text: widget.producto['precio']?.toString() ?? '',
  );

  categoriaCtrl = TextEditingController(
    text: widget.producto['categoria'] ?? '',
  );

  stockCtrl = TextEditingController(
    text: widget.producto['stock']?.toString() ?? '',
  );

  webCtrl = TextEditingController(
    text: widget.producto['pagina_web'] ?? '',
  );

  facebookCtrl = TextEditingController(
    text: widget.producto['facebook'] ?? '',
  );

  telefonoCtrl = TextEditingController(
    text: widget.producto['telefono'] ?? '',
  );

  lat = widget.producto['latitud'];
  lng = widget.producto['longitud'];
  
  latCtrl = TextEditingController(
  text: lat?.toString() ?? '',
);

lngCtrl = TextEditingController(
  text: lng?.toString() ?? '',
);

  galeria = List<Map<String, dynamic>>.from(widget.producto['galeria'] ?? []);
  videos = List.from(widget.producto['videos'] ?? []);
  productos = List<Map<String, dynamic>>.from(widget.producto['productos'] ?? []);
}

  /// =========================
  /// UPLOAD
  /// =========================
  Future<String> upload(File file, String folder) async {
    final ext = file.path.split('.').last;
    final path = '${uuid.v4()}.$ext';

    await storage.upload('$folder/$path', file);
    return storage.getPublicUrl('$folder/$path');
  }

  /// =========================
  /// PICKERS
  /// =========================

  Future<void> pickImagenPrincipal() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => nuevaImagenPrincipal = File(img.path));
    }
  }

Future<void> pickGaleria() async {
  final imgs = await picker.pickMultiImage();
  if (imgs.isNotEmpty) {
    setState(() {
      nuevasGaleria.addAll(imgs.map((e) => File(e.path)));
      descripcionNuevas.addAll(List.generate(imgs.length, (_) => ''));
    });
  }
}

  Future<void> pickVideo() async {
    final vid = await picker.pickVideo(source: ImageSource.gallery);
    if (vid != null) {
      setState(() => nuevosVideos.add(File(vid.path)));
    }
  }

  Future<void> agregarProducto() async {
  final nombre = TextEditingController();
  final precio = TextEditingController();
  File? imagen;

  bool guardando = false;

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('Nuevo producto'),
          content: SingleChildScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: nombre,
        decoration: const InputDecoration(labelText: 'Nombre'),
      ),
      TextField(
        controller: precio,
        decoration: const InputDecoration(labelText: 'Precio'),
      ),

      if (imagen != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Image.file(
            imagen!,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),

      const SizedBox(height: 10),

      ElevatedButton(
        onPressed: () async {
          final img = await picker.pickImage(source: ImageSource.gallery);
          if (img != null) {
            setStateDialog(() => imagen = File(img.path));
          }
        },
        child: const Text('Seleccionar imagen'),
      ),
    ],
  ),
),
          actions: [
            ElevatedButton(
  onPressed: guardando
      ? null
      : () async {
          setStateDialog(() => guardando = true); // 🔥 ACTIVA LOADING

          String? url;

          if (imagen != null) {
            url = await upload(imagen!, 'productos');
          }

          setState(() {
            productos.add({
              'nombre': nombre.text,
              'precio': double.tryParse(precio.text),
              'imagen': url,
            });
          });

          Navigator.pop(context);
        },

  child: guardando
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Text('Guardar'),
)
          ],
        );
      },
    ),
  );
}

  /// =========================
  /// GUARDAR
  /// =========================
  Future<void> guardar() async {
    if (lat == null || lng == null) {
  setState(() => loading = false); // 👈 FIX
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Selecciona ubicación')),
  );
  return;
}
  setState(() => loading = true);

  try {
    String imagenPrincipal = widget.producto['imagen_principal'];

    if (nuevaImagenPrincipal != null) {
      imagenPrincipal =
          await upload(nuevaImagenPrincipal!, 'principal');
    }

    // 🔥 FIX: evitar crash por índice
    for (int i = 0; i < nuevasGaleria.length; i++) {
      final file = nuevasGaleria[i];
      final url = await upload(file, 'galeria');

      galeria.add({
        'url': url,
        'descripcion': i < descripcionNuevas.length
            ? descripcionNuevas[i]
            : '',
      });
    }

    for (var file in nuevosVideos) {
      final url = await upload(file, 'videos');
      videos.add(url);
    }

    await db.update({
      'nombre': nombreCtrl.text,
      'descripcion': descripcionCtrl.text,
      'precio': double.tryParse(precioCtrl.text),
      'categoria': categoriaCtrl.text,
      'stock': int.tryParse(stockCtrl.text),
      'imagen_principal': imagenPrincipal,
      'galeria': galeria,
      'videos': videos,
      'productos': productos,
      'pagina_web': webCtrl.text,
      'facebook': facebookCtrl.text,
      'telefono': telefonoCtrl.text,
      'latitud': lat,
      'longitud': lng,
    }).eq('id', widget.producto['id']);

    // 🔥 FIX CRÍTICO: limpiar estado para evitar duplicados
    nuevasGaleria.clear();
    descripcionNuevas.clear();
    nuevosVideos.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cambios guardados')),
    );

    Navigator.pop(context, true);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al guardar: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => loading = false);
  }
}

  /// =========================
  /// UI
  /// =========================
Widget _seccion(String titulo, Widget child) {
  return Card(
    margin: const EdgeInsets.only(bottom: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar tienda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _seccion(
  "Información general",
  Column(
    children: [
      TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
      TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
      TextField(controller: precioCtrl, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: TextInputType.number),
      TextField(controller: categoriaCtrl, decoration: const InputDecoration(labelText: 'Categoría')),
      TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
    ],
  ),
),

          const SizedBox(height: 20),

          /// IMAGEN PRINCIPAL
          const Text('Imagen principal'),
          GestureDetector(
            onTap: pickImagenPrincipal,
            child: Container(
              height: 150,
              color: Colors.grey[300],
              child: nuevaImagenPrincipal != null
                  ? Image.file(nuevaImagenPrincipal!, fit: BoxFit.cover)
                  : Image.network(widget.producto['imagen_principal'],
                      fit: BoxFit.cover),
            ),
          ),

          const SizedBox(height: 20),

          /// 📦 GALERÍA DRAG & DROP
          _seccion(
  "Galería",
  Column(
    children: [

      /// 🔴 EXISTENTES
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(galeria.length, (i) {
          final item = galeria[i];

          return Container(
            width: 120,
            child: Column(
              children: [
                Stack(
                  children: [
                    Image.network(item['url'], height: 80, fit: BoxFit.cover),

                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => galeria.removeAt(i));
                        },
                      ),
                    )
                  ],
                ),

                TextFormField(
                  initialValue: item['descripcion'] ?? '',
                  onChanged: (v) => galeria[i]['descripcion'] = v,
                  decoration: const InputDecoration(
                    hintText: 'Descripción',
                  ),
                ),
              ],
            ),
          );
        }),
      ),

      const SizedBox(height: 15),

      /// 🟢 NUEVAS (PREVIEW)
      if (nuevasGaleria.isNotEmpty) ...[
        const Align(
          alignment: Alignment.centerLeft,
          child: Text("Nuevas imágenes"),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(nuevasGaleria.length, (i) {
            final file = nuevasGaleria[i];

            return Container(
  width: 120,
  child: Column(
    children: [
      Stack(
        children: [
          Image.file(file, height: 80, fit: BoxFit.cover),

          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  nuevasGaleria.removeAt(i);
                  descripcionNuevas.removeAt(i);
                });
              },
            ),
          )
        ],
      ),

      SizedBox(
  height: 40,
  child: TextField(
    maxLines: 1,
    onChanged: (v) {
      descripcionNuevas[i] = v;
    },
    decoration: const InputDecoration(
      hintText: 'Descripción',
      isDense: true,
    ),
  ),
),
    ],
  ),
);
          }),
        ),
      ],

      const SizedBox(height: 10),

      TextButton(
        onPressed: pickGaleria,
        child: const Text('Agregar imágenes'),
      ),
    ],
  ),
),

          const SizedBox(height: 20),

          /// 🎥 VIDEOS
          _seccion(
  "Videos",
  Column(
    children: [

      /// 🔴 VIDEOS EXISTENTES
      ...videos.asMap().entries.map((e) {
        int i = e.key;
        String url = e.value;

        return Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPlayerWidget(videoUrl: url),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() => videos.removeAt(i));
                },
              ),
            ),

            const SizedBox(height: 10),
          ],
        );
      }),

      /// 🟢 NUEVOS VIDEOS
      ...nuevosVideos.map((file) {
        return Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPlayerWidget(
                videoUrl: file.path, // 👈 preview local
                isLocal: true, // 👈 IMPORTANTE (ajusta tu widget)
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() => nuevosVideos.remove(file));
                },
              ),
            ),

            const SizedBox(height: 10),
          ],
        );
      }),

      ElevatedButton(
        onPressed: pickVideo,
        child: const Text('Agregar video'),
      ),
    ],
  ),
),

          const SizedBox(height: 20),

          /// 🛍️ PRODUCTOS EDITABLES
          const Text('Productos'),
          Column(
            children: productos.asMap().entries.map((e) {
              int i = e.key;
              var p = e.value;

              return Card(
  child: ListTile(
    leading: p['imagen'] != null
        ? Image.network(p['imagen'], width: 50, fit: BoxFit.cover)
        : const Icon(Icons.image),

    title: Text(p['nombre'] ?? ''),
    subtitle: Text('\$${p['precio'] ?? ''}'),

    trailing: IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () => setState(() => productos.removeAt(i)),
    ),

    onTap: () async {
  final nombreCtrl = TextEditingController(text: p['nombre']);
  final precioCtrl = TextEditingController(text: '${p['precio']}');
  File? imagenNueva;

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('Editar producto'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: precioCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio'),
                  ),

                  const SizedBox(height: 10),

                  /// IMAGEN ACTUAL o NUEVA
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imagenNueva != null
                        ? Image.file(
                            imagenNueva!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : (p['imagen'] != null
                            ? Image.network(
                                p['imagen'],
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox()),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () async {
                      final img = await picker.pickImage(
                          source: ImageSource.gallery);
                      if (img != null) {
                        setStateDialog(
                            () => imagenNueva = File(img.path));
                      }
                    },
                    child: const Text('Cambiar imagen'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                String? url = p['imagen'];

                if (imagenNueva != null) {
                  url = await upload(imagenNueva!, 'productos');
                }

                setState(() {
                  productos[i] = {
                    'nombre': nombreCtrl.text,
                    'precio': double.tryParse(precioCtrl.text),
                    'imagen': url,
                  };
                });

                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ),
  );
},
  ),
);
            }).toList(),
          ),
          ElevatedButton(
  onPressed: agregarProducto,
  child: const Text('Agregar producto'),
),


          _seccion(
  "Contacto",
  Column(
    children: [
      TextField(controller: webCtrl, decoration: const InputDecoration(labelText: 'Página web')),
      TextField(controller: facebookCtrl, decoration: const InputDecoration(labelText: 'Facebook')),
      TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
    ],
  ),
),

          const SizedBox(height: 20),

          /// 📍 MAPA
          _seccion(
  "Ubicación manual",
  Column(
    children: [
      TextField(
        controller: latCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Latitud'),
        onChanged: (v) {
          lat = double.tryParse(v);
        },
      ),
      TextField(
        controller: lngCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Longitud'),
        onChanged: (v) {
          lng = double.tryParse(v);
        },
      ),
    ],
  ),
),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: loading ? null : guardar,
            child: loading
                ? const CircularProgressIndicator()
                : const Text('Guardar cambios'),
          )
        ],
      ),
    );
  }
}