import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';



class PublicarFestividadPage extends StatefulWidget {
  final Map<String, dynamic>? festividadEditar;

  const PublicarFestividadPage({
    super.key,
    this.festividadEditar,
  });

  @override
  State<PublicarFestividadPage> createState() =>
      _PublicarFestividadPageState();
}


class _PublicarFestividadPageState
    extends State<PublicarFestividadPage> {

      String formatearDia(String dia) {
    if (dia.isEmpty) return dia;
    return dia[0].toUpperCase() + dia.substring(1);
  }

  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final latCtrl = TextEditingController();
final lngCtrl = TextEditingController();
final fechaInicioCtrl = TextEditingController();
final fechaFinCtrl = TextEditingController();


List<Map<String, dynamic>> programa = [];

final horaCtrl = TextEditingController();
final actividadCtrl = TextEditingController();
final diaCtrl = TextEditingController();

  List<File> imagenes = [];
  List<File> videos = [];
  List<VideoPlayerController> videoControllers = [];
  /// 🔥 EXISTENTES (cuando es edición)
List<String> imagenesExistentes = [];
List<String> videosExistentes = [];


  bool loading = false;
  String? diaSeleccionado;

  void agregarActividad() {
  if (diaSeleccionado == null ||
      horaCtrl.text.isEmpty ||
      actividadCtrl.text.isEmpty) return;

  setState(() {

    programa.add({
      "dia": diaSeleccionado,
      "hora": horaCtrl.text,
      "actividad": actividadCtrl.text,
    });

    programa.sort((a, b) {
  final diaCompare = a["dia"]!.compareTo(b["dia"]!);
  if (diaCompare != 0) return diaCompare;

  return a["hora"]!.compareTo(b["hora"]!);
});

    /// ❌ NO BORRAR EL DIA
    // diaCtrl.clear();

    horaCtrl.clear();
    actividadCtrl.clear();
  });
}

  Future<void> seleccionarFecha(TextEditingController controller) async {

  DateTime? fecha = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2024),
    lastDate: DateTime(2035),
  );

  if (fecha != null) {
    setState(() {
      controller.text = fecha.toIso8601String();
    });
  }
}

  Future<Uint8List?> generarMiniatura(String url) async {
  try {
    final uint8list = await VideoThumbnail.thumbnailData(
      video: url,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 200,
      quality: 75,
    );

    return uint8list;
  } catch (e) {
    return null;
  }
}


  /// 🔹 LIMPIAR TITULO PARA USARLO COMO CARPETA
  String limpiarTitulo(String titulo) {
    return titulo
        .trim()
        .toLowerCase()
        .replaceAll(" ", "_")
        .replaceAll(RegExp(r'[^\w\s-]'), '');
  }

  Future<void> seleccionarImagenes() async {
    final List<XFile> picked = await _picker.pickMultiImage();

    if (picked.isNotEmpty) {
      setState(() {
        imagenes.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  Future<void> seleccionarVideo() async {
    final XFile? video =
        await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      final file = File(video.path);
      final controller = VideoPlayerController.file(file);

      await controller.initialize();
      controller.setLooping(true);

      setState(() {
        videos.add(file);
        videoControllers.add(controller);
      });
    }
  }

  Future<List<Map<String,dynamic>>> cargarActividades() async {

  final supabase = Supabase.instance.client;

  final data = await supabase
      .from('festividad_actividades')
      .select()
      .eq('festividad_id', widget.festividadEditar!['id'])
      .order('hora_inicio');

  return List<Map<String,dynamic>>.from(data);
}

  /// 🔹 SUBIR ARCHIVOS A STORAGE ORGANIZADOS POR TITULO
  Future<List<String>> subirArchivos(
      List<File> archivos, String tipo) async {

    final supabase = Supabase.instance.client;
    List<String> urls = [];

    final tituloCarpeta = limpiarTitulo(tituloCtrl.text);

    for (int i = 0; i < archivos.length; i++) {
      final file = archivos[i];

      final nombre =
          "${DateTime.now().millisecondsSinceEpoch}_$i";

      final path = "$tituloCarpeta/$tipo/$nombre";

      await supabase.storage
          .from('festividades')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = supabase.storage
          .from('festividades')
          .getPublicUrl(path);

      urls.add(url);
    }

    return urls;
  }
  

  Future<void> publicar() async {
  if (tituloCtrl.text.trim().isEmpty ||
      descripcionCtrl.text.trim().isEmpty) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Título y descripción obligatorios"),
      ),
    );
    return;
  }

  setState(() => loading = true);

  try {
    final supabase = Supabase.instance.client;

    final nuevasImagenUrls =
        await subirArchivos(imagenes, "imagenes");

    final nuevosVideoUrls =
        await subirArchivos(videos, "videos");

    final imagenFinal = [
      ...imagenesExistentes,
      ...nuevasImagenUrls,
    ];

    final videoFinal = [
      ...videosExistentes,
      ...nuevosVideoUrls,
    ];

    if (widget.festividadEditar == null) {

      /// 🆕 NUEVA
      await supabase.from('festividades').insert({
  'titulo': tituloCtrl.text.trim(),
  'descripcion': descripcionCtrl.text.trim(),
  'imagenes': imagenFinal,
  'videos': videoFinal,
  'fecha_inicio': fechaInicioCtrl.text,
  'fecha_fin': fechaFinCtrl.text,
  'programa': List.from(programa),
  'fecha': DateTime.now().toIso8601String(),
  'latitud': latCtrl.text.isNotEmpty
    ? double.parse(latCtrl.text)
    : null,

'longitud': lngCtrl.text.isNotEmpty
    ? double.parse(lngCtrl.text)
    : null,
});

    } else {

      /// ✏ EDITAR
      await supabase
    .from('festividades')
    .update({
  'titulo': tituloCtrl.text.trim(),
  'descripcion': descripcionCtrl.text.trim(),
  'imagenes': imagenFinal,
  'videos': videoFinal,
  'fecha_inicio': fechaInicioCtrl.text,
  'fecha_fin': fechaFinCtrl.text,
  'programa': List.from(programa),
  'latitud': latCtrl.text.isNotEmpty
    ? double.parse(latCtrl.text)
    : null,

'longitud': lngCtrl.text.isNotEmpty
    ? double.parse(lngCtrl.text)
    : null,
})
.eq('id', widget.festividadEditar!['id']);
    }

    if (!mounted) return;

    Navigator.pop(context, true); // ✅ SOLO UNO

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  } finally {
    if (mounted) setState(() => loading = false);
  }
}


  @override
void initState() {
  super.initState();

  if (widget.festividadEditar != null) {

    tituloCtrl.text =
        widget.festividadEditar!['titulo'] ?? '';

    descripcionCtrl.text =
        widget.festividadEditar!['descripcion'] ?? '';

    fechaInicioCtrl.text =
        widget.festividadEditar!['fecha_inicio'] ?? '';

    fechaFinCtrl.text =
        widget.festividadEditar!['fecha_fin'] ?? '';

    latCtrl.text =
    widget.festividadEditar!['latitud']?.toString() ?? '';

lngCtrl.text =
    widget.festividadEditar!['longitud']?.toString() ?? '';

    imagenesExistentes =
        (widget.festividadEditar!['imagenes'] as List?)
                ?.cast<String>() ?? [];

    videosExistentes =
        (widget.festividadEditar!['videos'] as List?)
                ?.cast<String>() ?? [];

    /// 🔥 CARGAR PROGRAMA
    final programaDB = widget.festividadEditar!['programa'];

    if (programaDB != null) {

      programa = List<Map<String, dynamic>>.from(
        programaDB.map(
          (e) => {
            "dia": e["dia"].toString(),
            "hora": e["hora"].toString(),
            "actividad": e["actividad"].toString(),
          },
        ),
      );

      /// 🔥 ESTABLECER PRIMER DIA
      if (programa.isNotEmpty) {
        diaSeleccionado = programa.first["dia"];
        diaCtrl.text = diaSeleccionado!;
      }
    }
  }
}



  @override
  void dispose() {
    for (var controller in videoControllers) {
      controller.dispose();
    }
    tituloCtrl.dispose();
    descripcionCtrl.dispose();
    latCtrl.dispose();
lngCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    final diasUnicos = programa
    .map((e) => e["dia"].toString())
    .toSet()
    .toList();

    final actividadesDelDia = programa
    .where((a) => a["dia"] == diaSeleccionado)
    .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
  widget.festividadEditar == null? "Publicar Festividad": "Editar Festividad",),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            TextField(
              controller: tituloCtrl,
              decoration: const InputDecoration(
                labelText: "Título",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 15),

/// FECHA DE INICIO
TextField(
  controller: fechaInicioCtrl,
  readOnly: true,
  onTap: () => seleccionarFecha(fechaInicioCtrl),
  decoration: const InputDecoration(
    labelText: "Fecha de inicio",
    border: OutlineInputBorder(),
    suffixIcon: Icon(Icons.calendar_today),
  ),
),

const SizedBox(height: 15),

/// FECHA DE FINALIZACIÓN
TextField(
  controller: fechaFinCtrl,
  readOnly: true,
  onTap: () => seleccionarFecha(fechaFinCtrl),
  decoration: const InputDecoration(
    labelText: "Fecha de finalización",
    border: OutlineInputBorder(),
    suffixIcon: Icon(Icons.calendar_today),
  ),
),

const SizedBox(height: 25),

const Text(
  "Programa del evento",
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),

const SizedBox(height: 10),

DropdownButtonFormField<String>(
  value: diasUnicos.contains(diaSeleccionado)
      ? diaSeleccionado
      : null,
  hint: const Text("Selecciona un día"),
  items: diasUnicos.map((dia) {
    return DropdownMenuItem(
      value: dia,
      child: Text(formatearDia(dia)),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      diaSeleccionado = value;
      diaCtrl.text = value ?? "";
    });
  },
  decoration: const InputDecoration(
    labelText: "Día del evento",
    border: OutlineInputBorder(),
  ),
),

TextButton.icon(
  onPressed: () async {
    final nuevoDia = await showDialog<String>(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();

        return AlertDialog(
          title: const Text("Nuevo día"),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: "Ej: 5 Mayo",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, ctrl.text),
              child: const Text("Agregar"),
            ),
          ],
        );
      },
    );

    if (nuevoDia != null && nuevoDia.trim().isNotEmpty) {
      final limpio = nuevoDia.trim().toLowerCase();

      setState(() {
        diaSeleccionado = limpio;
        diaCtrl.text = limpio;
      });
    }
  },
  icon: const Icon(Icons.add),
  label: const Text("Agregar nuevo día"),
),
const SizedBox(height: 10),


TextField(
  controller: horaCtrl,
  decoration: const InputDecoration(
    labelText: "Hora (ej: 08:00 AM)",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 10),

TextField(
  controller: actividadCtrl,
  decoration: const InputDecoration(
    labelText: "Actividad",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 10),

ElevatedButton.icon(
  onPressed: agregarActividad,
  icon: const Icon(Icons.add),
  label: const Text("Agregar actividad"),
),

ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: actividadesDelDia.length,
  itemBuilder: (context, index) {

    final item = actividadesDelDia[index];
    final realIndex = programa.indexOf(item);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: Text(item["actividad"] ?? ""),

        // ✅ CORREGIDO AQUÍ
        subtitle: Text(
          "${formatearDia(item["dia"] ?? "")} - ${item["hora"]}",
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                diaCtrl.text = item["dia"] ?? "";
                horaCtrl.text = item["hora"] ?? "";
                actividadCtrl.text = item["actividad"] ?? "";

                setState(() {
                  programa.removeAt(realIndex);
                });
              },
            ),

            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  programa.removeAt(realIndex);
                });
              },
            ),
          ],
        ),
      ),
    );
  },
),


            /// 🔥 IMÁGENES EXISTENTES (EDICIÓN)
if (imagenesExistentes.isNotEmpty) ...[
  const Text(
    "Imágenes existentes",
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 10),

  Wrap(
    spacing: 10,
    runSpacing: 10,
    children: imagenesExistentes.map((url) => Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            height: 120,
            width: 120,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                imagenesExistentes.remove(url);
              });
            },
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.red,
              child: Icon(Icons.close,
                  color: Colors.white, size: 18),
            ),
          ),
        )
      ],
    )).toList(),
  ),

  const SizedBox(height: 20),
],


            /// 🔹 PREVISUALIZACION IMAGENES
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
                      onTap: () =>
                          setState(() => imagenes.remove(img)),
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  )
                ],
              )).toList(),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: seleccionarImagenes,
              icon: const Icon(Icons.image),
              label: const Text("Agregar Imágenes"),
            ),

            const SizedBox(height: 20),

            /// 🔥 VIDEOS EXISTENTES (EDICIÓN)
if (videosExistentes.isNotEmpty) ...[
  const Text(
    "Videos existentes",
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 10),

  Wrap(
    spacing: 10,
    runSpacing: 10,
    children: videosExistentes.map((url) => Stack(
      children: [

        FutureBuilder<Uint8List?>(
          future: generarMiniatura(url),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return Container(
                height: 120,
                width: 120,
                alignment: Alignment.center,
                color: Colors.black12,
                child: const CircularProgressIndicator(),
              );
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                snapshot.data!,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            );
          },
        ),

        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                videosExistentes.remove(url);
              });
            },
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.red,
              child: Icon(Icons.close,
                  color: Colors.white, size: 18),
            ),
          ),
        ),

        /// 🔥 ICONO PLAY ENCIMA
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    )).toList(),
  ),

  const SizedBox(height: 20),
],



            /// 🔹 PREVISUALIZACION VIDEOS
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: videoControllers.length,
              itemBuilder: (context, index) {
                final controller = videoControllers[index];

                return Column(
                  children: [
                    AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                    const SizedBox(height: 10),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      onPressed: () {
                        setState(() {
                          controller.dispose();
                          videoControllers.removeAt(index);
                          videos.removeAt(index);
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                  ],
                );
              },
            ),

            ElevatedButton.icon(
              onPressed: seleccionarVideo,
              icon: const Icon(Icons.videocam),
              label: const Text("Agregar Video"),
            ),

            const SizedBox(height: 30),

            const Text(
  "Ubicación",
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),

const SizedBox(height: 10),

TextField(
  controller: latCtrl,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
    labelText: "Latitud",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 10),

TextField(
  controller: lngCtrl,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
    labelText: "Longitud",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : publicar,
                icon: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label:
                    Text(loading ? "Publicando..." : "Publicar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
