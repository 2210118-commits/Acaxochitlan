import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditarExperienciaMagicaPage extends StatefulWidget {

  final Map<String, dynamic> lugar;

  const EditarExperienciaMagicaPage({
    super.key,
    required this.lugar,
  });

  @override
  State<EditarExperienciaMagicaPage> createState() =>
      _EditarExperienciaMagicaPageState();
}

class _EditarExperienciaMagicaPageState
    extends State<EditarExperienciaMagicaPage> {

  final supabase =
      Supabase.instance.client;

  final nombreController =
      TextEditingController();

  final descripcionController =
      TextEditingController();

  final ubicacionController =
      TextEditingController();

  final telefonoController =
      TextEditingController();

  final horarioController =
      TextEditingController();

  final whatsappController =
      TextEditingController();

  final facebookController =
      TextEditingController();

  final mapsController =
      TextEditingController();

  final latitudController =
      TextEditingController();

  final longitudController =
      TextEditingController();

  final categorias = [

    "Taquerías",
    "Heladeros",
    "Eloteros",
    "Hamburguesas",
    "Antojitos",
    "Postres",
    "Cafeterías",
    "Otros",
    "",
    "Cocineras tradicionales",

  ];

  String categoria = "Taquerías";

  bool cargando = false;

  List<String> imagenesActuales = [];

  List<File> nuevasImagenes = [];
  List<Map<String, dynamic>> galeriaExtraActual = [];

List<File> nuevasImagenesExtra = [];
List<TextEditingController>
    descripcionesActualesExtra = [];

List<TextEditingController>
    descripcionesImagenesExtra = [];

  List<String> videosActuales = [];
List<File> nuevosVideos = [];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  void cargarDatos() {

    final lugar = widget.lugar;

    nombreController.text =
        lugar['nombre'] ?? '';

    descripcionController.text =
        lugar['descripcion'] ?? '';

    ubicacionController.text =
        lugar['ubicacion'] ?? '';

    telefonoController.text =
        lugar['telefono'] ?? '';

    horarioController.text =
        lugar['horario'] ?? '';

    whatsappController.text =
        lugar['whatsapp'] ?? '';

    facebookController.text =
        lugar['facebook'] ?? '';

    mapsController.text =
        lugar['maps_url'] ?? '';

    latitudController.text =
        (lugar['latitud'] ?? '')
            .toString();

    longitudController.text =
        (lugar['longitud'] ?? '')
            .toString();

    categoria =
        lugar['categoria'] ??
            "Taquerías";

    imagenesActuales =
        List<String>.from(
      lugar['imagenes'] ?? [],
    );

    galeriaExtraActual =
    List<Map<String, dynamic>>.from(
  widget.lugar['galeria_extra'] ?? [],
);
descripcionesActualesExtra =
    galeriaExtraActual.map((item) {
  return TextEditingController(
    text: item["descripcion"] ?? "",
  );
}).toList();

    videosActuales =
    List<String>.from(
      lugar['videos'] ?? [],
    );
  }

  Future<void>
      seleccionarImagenes() async {

    final picked =
        await ImagePicker()
            .pickMultiImage(
      imageQuality: 80,
    );

    if (picked.isEmpty) return;

    setState(() {

      nuevasImagenes.addAll(
        picked.map(
          (e) => File(e.path),
        ),
      );
    });
  }

  Future<void> agregarImagenExtra() async {
  final XFile? imagen =
      await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
  );

  if (imagen == null) return;

  setState(() {
    nuevasImagenesExtra.add(
      File(imagen.path),
    );

    descripcionesImagenesExtra.add(
      TextEditingController(),
    );
  });
}

  Future<void> seleccionarVideo() async {

  final picked =
      await ImagePicker()
          .pickVideo(
    source: ImageSource.gallery,
  );

  if (picked == null) return;

  setState(() {

    nuevosVideos.add(
      File(picked.path),
    );

  });
}

  void eliminarImagenActual(int index) {
  setState(() {
    imagenesActuales.removeAt(index);
  });
}

void establecerComoPrincipal(int index) {
  setState(() {
    final imagen = imagenesActuales.removeAt(index);
    imagenesActuales.insert(0, imagen);
  });
}

void eliminarImagenExtraActual(int index) {
  setState(() {
    descripcionesActualesExtra[index]
        .dispose();
    descripcionesActualesExtra
        .removeAt(index);
    galeriaExtraActual.removeAt(index);
  });
}

void eliminarImagenExtraNueva(int index) {
  setState(() {
    descripcionesImagenesExtra[index].dispose();
    descripcionesImagenesExtra.removeAt(index);
    nuevasImagenesExtra.removeAt(index);
  });
}
  

  void eliminarImagenNueva(
      int index) {

    setState(() {

      nuevasImagenes
          .removeAt(index);
    });
  }

  void eliminarTodosLosVideos() {

  setState(() {

    videosActuales.clear();

    nuevosVideos.clear();

  });
}

  Future<void>
      actualizarLugar() async {
        

    try {

      setState(() {

        cargando = true;
      });

      for (int i = 0; i < galeriaExtraActual.length; i++) {
  galeriaExtraActual[i]["descripcion"] =
      descripcionesActualesExtra[i]
          .text
          .trim();
}

      List<String>
          imagenesFinales = [];

      imagenesFinales
          .addAll(
        imagenesActuales,
      );

      for (int i = 0; i < nuevasImagenes.length; i++) {

  final nombreArchivo =
      "${DateTime.now().millisecondsSinceEpoch}_edit_$i.jpg";

  final comprimida =
      await FlutterImageCompress.compressAndGetFile(
    nuevasImagenes[i].path,
    "${nuevasImagenes[i].path}_comprimida.jpg",
    quality: 70,
    minWidth: 900,
    minHeight: 900,
    keepExif: false,
  );

  final archivo =
      File(comprimida?.path ?? nuevasImagenes[i].path);

  await supabase.storage
      .from('experiencia-magica')
      .upload(
        nombreArchivo,
        archivo,
      );

  final url = supabase.storage
      .from('experiencia-magica')
      .getPublicUrl(nombreArchivo);

  imagenesFinales.add(url);
}

List<Map<String, dynamic>>
    galeriaExtraFinal = [];

galeriaExtraFinal.addAll(
  galeriaExtraActual,
);

for (int i = 0;
    i < nuevasImagenesExtra.length;
    i++) {

  final nombreArchivo =
      "${DateTime.now().millisecondsSinceEpoch}_extra_$i.jpg";

  await supabase.storage
      .from('experiencia-magica')
      .upload(
        nombreArchivo,
        nuevasImagenesExtra[i],
      );

  final url = supabase.storage
      .from('experiencia-magica')
      .getPublicUrl(
        nombreArchivo,
      );

  galeriaExtraFinal.add({
    'imagen': url,
    'descripcion':
        descripcionesImagenesExtra[i]
            .text
            .trim(),
  });
}

      List<String> videosFinales = [];

videosFinales.addAll(
  videosActuales,
);

for (int i = 0;
    i < nuevosVideos.length;
    i++) {

  final nombreVideo =
      "${DateTime.now().millisecondsSinceEpoch}_video_$i.mp4";

  await supabase.storage
      .from('experiencia-magica')
      .upload(
        nombreVideo,
        nuevosVideos[i],
      );

  final url = supabase.storage
      .from('experiencia-magica')
      .getPublicUrl(
        nombreVideo,
      );

  videosFinales.add(url);
}

      await supabase
          .from(
              'experiencia_magica')
          .update({

        'nombre':
            nombreController.text,

        'descripcion':
            descripcionController.text,

        'ubicacion':
            ubicacionController.text,

        'categoria':
            categoria,

        'imagen_principal': imagenesFinales.isNotEmpty
    ? imagenesFinales.first
    : null,


        'imagenes':
            imagenesFinales,

        'galeria_extra': galeriaExtraFinal,

        'videos': videosFinales,

        'telefono':
            telefonoController.text,

        'horario':
            horarioController.text,

        'whatsapp':
            whatsappController.text,

        'facebook':
            facebookController.text,

        'maps_url':
            mapsController.text,

        'latitud':
            double.tryParse(
          latitudController.text,
        ),

        'longitud':
            double.tryParse(
          longitudController.text,
        ),

      }).eq(
        'id',
        widget.lugar['id'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
              context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Cambios guardados",
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );

    } catch (e) {

      ScaffoldMessenger.of(
              context)
          .showSnackBar(

        SnackBar(
          content:
              Text("Error: $e"),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {

          cargando = false;
        });
      }
    }
  }
    Future<void> eliminarLugar() async {

    final confirmar = await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          title: const Text(
            "Eliminar establecimiento",
          ),

          content: const Text(
            "¿Deseas eliminar este establecimiento?\n\nEsta acción no se puede deshacer.",
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                "Cancelar",
              ),
            ),

            ElevatedButton(

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),

              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child: const Text(
                "Eliminar",
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {

      await supabase
          .from(
              'experiencia_magica')
          .delete()
          .eq(
            'id',
            widget.lugar['id'],
          );

      if (!mounted) return;

      ScaffoldMessenger.of(
              context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Establecimiento eliminado",
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );

    } catch (e) {

      ScaffoldMessenger.of(
              context)
          .showSnackBar(

        SnackBar(
          content:
              Text("Error: $e"),
        ),
      );
    }
  }

  Widget campo({

    required TextEditingController controller,
    required String label,
    int maxLines = 1,

  }) {

    return Padding(

      padding:
          const EdgeInsets.only(
        bottom: 15,
      ),

      child: TextField(

        controller: controller,

        maxLines: maxLines,

        decoration: InputDecoration(

          labelText: label,

          filled: true,

          fillColor: Colors.white,

          border:
              OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Editar establecimiento",
        ),

        actions: [

          IconButton(

            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),

            onPressed:
                eliminarLugar,
          ),
        ],
      ),

      body:
          SingleChildScrollView(

        padding:
            const EdgeInsets.all(
          20,
        ),

        child: Column(

          children: [

            campo(
              controller:
                  nombreController,
              label: "Nombre",
            ),

            DropdownButtonFormField(

              value: categoria,

              decoration:
                  InputDecoration(

                labelText:
                    "Categoría",

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),

              items: categorias
                  .map((e) {

                return DropdownMenuItem(
                  value: e,
                  child: Text(e),
                );
              }).toList(),

              onChanged: (value) {

                setState(() {

                  categoria =
                      value!;
                });
              },
            ),

            const SizedBox(
              height: 15,
            ),

            campo(
              controller:
                  ubicacionController,
              label: "Ubicación",
            ),

            campo(
              controller:
                  telefonoController,
              label: "Teléfono",
            ),

            campo(
              controller:
                  horarioController,
              label: "Horario",
            ),

            campo(
              controller:
                  whatsappController,
              label: "WhatsApp",
            ),

            campo(
              controller:
                  facebookController,
              label: "Facebook",
            ),

            campo(
              controller:
                  mapsController,
              label:
                  "Google Maps",
            ),

            campo(
              controller:
                  latitudController,
              label:
                  "Latitud",
            ),

            campo(
              controller:
                  longitudController,
              label:
                  "Longitud",
            ),

            campo(
              controller:
                  descripcionController,
              label:
                  "Descripción",
              maxLines: 5,
            ),

            const SizedBox(
              height: 20,
            ),

            const Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                "Imágenes actuales",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            SizedBox(

              height: 120,

              child:
                  ListView.builder(

                scrollDirection:
                    Axis.horizontal,

                itemCount:
                    imagenesActuales
                        .length,

                itemBuilder:
                    (_, index) {

                  return Stack(

                    children: [

                      Container(

                        width: 120,

                        margin:
                            const EdgeInsets.only(
                          right: 10,
                        ),

                        child:
                            ClipRRect(

                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),

                          child:
                              Image.network(
                            imagenesActuales[
                                index],
                            fit: BoxFit
                                .cover,
                          ),
                        ),
                      ),

                      Positioned(
  left: 5,
  bottom: 5,
  child: GestureDetector(
    onTap: () {
      establecerComoPrincipal(index);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        index == 0 ? "Principal" : "Hacer principal",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    ),
  ),
),

                      Positioned(

                        right: 5,

                        top: 5,

                        child:
                            CircleAvatar(

                          radius: 14,

                          backgroundColor:
                              Colors.red,

                          child:
                              IconButton(

                            padding:
                                EdgeInsets.zero,

                            icon:
                                const Icon(
                              Icons.close,
                              color:
                                  Colors.white,
                              size:
                                  14,
                            ),

                            onPressed: () {
                              eliminarImagenActual(
                                index,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(

              onPressed:
                  seleccionarImagenes,

              icon: const Icon(
                Icons.image,
              ),

              label: const Text(
                "Agregar imágenes",
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            ElevatedButton.icon(
  onPressed: agregarImagenExtra,
  icon: const Icon(
    Icons.add_photo_alternate,
  ),
  label: const Text(
    "Agregar imagen extra",
  ),
),
...List.generate(
  nuevasImagenesExtra.length,
  (index) => Card(
    margin: const EdgeInsets.only(bottom: 15),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Image.file(
            nuevasImagenesExtra[index],
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          const SizedBox(height: 10),

          TextField(
            controller:
                descripcionesImagenesExtra[index],
            decoration: const InputDecoration(
              labelText:
                  "Descripción de la imagen",
            ),
          ),

          IconButton(
            onPressed: () {
              eliminarImagenExtraNueva(index);
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          ),
        ],
      ),
    ),
  ),
),
const SizedBox(height: 15),

if (galeriaExtraActual.isNotEmpty)
  const Align(
    alignment: Alignment.centerLeft,
    child: Text(
      "Imágenes extra actuales",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

...List.generate(
  galeriaExtraActual.length,
  (index) => Card(
    margin: const EdgeInsets.only(bottom: 15),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Image.network(
            galeriaExtraActual[index]["imagen"],
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          const SizedBox(height: 10),

          TextField(
  controller:
      descripcionesActualesExtra[index],
  decoration: const InputDecoration(
    labelText: "Descripción",
    border: OutlineInputBorder(),
  ),
),

          IconButton(
            onPressed: () {
              eliminarImagenExtraActual(index);
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          ),
        ],
      ),
    ),
  ),
),

            if (videosActuales.isNotEmpty ||
    nuevosVideos.isNotEmpty)

  SizedBox(
    height: 90,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,

      itemCount:
          videosActuales.length +
          nuevosVideos.length,

      itemBuilder: (context, index) {

        return Container(
          width: 90,
          margin: const EdgeInsets.only(
            right: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.shade200,
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.video_library,
                size: 30,
                color: Colors.green,
              ),

              const SizedBox(height: 4),

              Text(
                "Video ${index + 1}",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    ),
  ),

            const SizedBox(
              height: 10,
            ),

            ElevatedButton.icon(

              onPressed:
                  seleccionarVideo,

              icon: const Icon(
                Icons.video_library,
              ),

              label: const Text(
  "Agregar video",
),
            ),

            TextButton.icon(

              onPressed:
    eliminarTodosLosVideos,

              icon: const Icon(
                Icons.delete,
              ),

              label: const Text(
                "Eliminar video",
              ),
            ),

            const SizedBox(
              height: 35,
            ),

            SizedBox(

              width:
                  double.infinity,

              height: 60,

              child:
                  ElevatedButton.icon(

                onPressed:
                    cargando
                        ? null
                        : actualizarLugar,

                icon: cargando

                    ? const SizedBox(

                        width: 20,
                        height: 20,

                        child:
                            CircularProgressIndicator(),
                      )

                    : const Icon(
                        Icons.save,
                      ),

                label: Text(

                  cargando

                      ? "Guardando..."

                      : "Guardar cambios",
                ),
              ),
            ),

            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}