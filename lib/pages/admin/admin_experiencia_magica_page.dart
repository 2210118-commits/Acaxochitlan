import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminExperienciaMagicaPage extends StatefulWidget {
  const AdminExperienciaMagicaPage({super.key});

  @override
  State<AdminExperienciaMagicaPage> createState() =>
      _AdminExperienciaMagicaPageState();
}

class _AdminExperienciaMagicaPageState
    extends State<AdminExperienciaMagicaPage> {

  final supabase = Supabase.instance.client;

  final tituloGeneralController =
      TextEditingController();

  final descripcionGeneralController =
      TextEditingController();

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

  List<File> imagenes = [];

  List<File> videos = [];

  bool cargando = false;

  String limpiarNombre(String texto) {
  return texto
      .trim()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('Á', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ú', 'U')
      .replaceAll('ñ', 'n')
      .replaceAll('Ñ', 'N')
      .replaceAll('ü', 'u')
      .replaceAll('Ü', 'U')
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'[^\w\-_]'), '_');
}

  @override
  void initState() {
    super.initState();
    cargarConfiguracion();
  }

  Future<void> cargarConfiguracion() async {

    try {

      final response = await supabase
          .from('experiencia_magica_config')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (response != null) {

        tituloGeneralController.text =
            response['titulo'] ?? '';

        descripcionGeneralController.text =
            response['descripcion'] ?? '';
      }

    } catch (_) {}
  }

  Future<void> guardarConfiguracion() async {

    try {

      await supabase
          .from('experiencia_magica_config')
          .upsert({

        'id': 1,

        'titulo':
            tituloGeneralController.text,

        'descripcion':
            descripcionGeneralController.text,

      });

      mensaje(
        "Texto general actualizado",
      );

    } catch (e) {

      mensaje("Error: $e");
    }
  }

  Future<void> seleccionarImagenes() async {

  final pickedFiles =
      await ImagePicker().pickMultiImage(
    imageQuality: 80,
  );

  if (pickedFiles.isEmpty) return;

  setState(() {
    imagenes =
        pickedFiles.map((e) => File(e.path)).toList();
  });
}

Future<void> seleccionarVideo() async {

  final picked =
      await ImagePicker().pickVideo(
    source: ImageSource.gallery,
  );

  if (picked == null) return;

  setState(() {

    videos.add(
      File(picked.path),
    );

  });
}

  Future<void> subirLugar() async {
    final nombreLugar =
    limpiarNombre(
      nombreController.text,
    );

    if (nombreController.text.trim().isEmpty ||
    imagenes.isEmpty) {
  mensaje(
    "El nombre y al menos una imagen son obligatorios",
  );
  return;
}

    try {

      setState(() {
        cargando = true;
      });

     List<String> urlsImagenes = [];

for (int i = 0; i < imagenes.length; i++) {

  final nombreArchivo =

      "$nombreLugar/"
      "imagen_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg";

  await supabase.storage
      .from('experiencia-magica')
      .upload(
        nombreArchivo,
        imagenes[i],
      );

  final imageUrl =
      supabase.storage
          .from('experiencia-magica')
          .getPublicUrl(
            nombreArchivo,
          );

  urlsImagenes.add(imageUrl);
}

List<String> videosUrls = [];

for (int i = 0; i < videos.length; i++) {

  final nombreVideo =
      "$nombreLugar/"
      "video_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.mp4";

  await supabase.storage
      .from('experiencia-magica')
      .upload(
        nombreVideo,
        videos[i],
      );

  final url = supabase.storage
      .from('experiencia-magica')
      .getPublicUrl(
        nombreVideo,
      );

  videosUrls.add(url);
}

      await supabase
          .from('experiencia_magica')
          .insert({

        'nombre':
            nombreController.text,

        'descripcion':
            descripcionController.text,

        'ubicacion':
            ubicacionController.text,

        'categoria': categoria,

        'imagenes': urlsImagenes,

        'videos': videosUrls,

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
        
        'latitud':double.tryParse(latitudController.text,),
        'longitud':double.tryParse(longitudController.text,),

      });

      mensaje(
        "Lugar subido correctamente",
      );

      limpiarCampos();

    } catch (e) {

      mensaje("Error: $e");

    } finally {

      setState(() {
        cargando = false;
      });
    }
  }

  void limpiarCampos() {

    final controllers = [

      nombreController,
      descripcionController,
      ubicacionController,
      telefonoController,
      horarioController,
      whatsappController,
      facebookController,
      mapsController,
      latitudController,
      longitudController,

    ];

    for (var c in controllers) {
      c.clear();
    }

    setState(() {

  imagenes.clear();

  videos.clear();

  categoria = "Taquerías";

});
  }

  void mensaje(String texto) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(texto),
      ),
    );
  }

  Widget campo({

    required TextEditingController controller,
    required String label,
    int maxLines = 1,

  }) {

    return Padding(

      padding:const EdgeInsets.only(bottom: 18,),

      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border:OutlineInputBorder(
            borderRadius:BorderRadius.circular(18,),
          ),
        ),
      ),
    );
  }

  Widget tarjeta({
    required Widget child,

  }) {

    return Container(
      width: double.infinity,
      padding:const EdgeInsets.all(20),
      margin:const EdgeInsets.only(
        bottom: 30,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:BorderRadius.circular(25),
        boxShadow: const [

          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),

      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ADMIN EXPERIENCIA MÁGICA",
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding:const EdgeInsets.all(20),
        child: Column(
          children: [

            /// TEXTO GENERAL
            tarjeta(
              child: Column(
                crossAxisAlignment:CrossAxisAlignment.start,

                children: [

                  const Text("Texto General",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  campo(
                    controller:tituloGeneralController,
                    label:"Título general",
                  ),

                  campo(
                    controller:descripcionGeneralController,
                    label:"Descripción general",
                    maxLines: 4,
                  ),

                  SizedBox( width: double.infinity,
                    height: 55,
                    child:ElevatedButton.icon(
                      style:ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.black,
                      ),

                      onPressed: guardarConfiguracion,
                      icon: const Icon(
                        Icons.save,
                      ),

                      label: const Text("Guardar texto general",
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// SUBIR LUGAR
            tarjeta(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text("Subir nuevo lugar",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text("Agrega establecimientos para mostrarlos en la app.",
                    style: TextStyle(
                      color:
                          Colors.black54,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),
                  campo(
                    controller:nombreController,
                    label:"Nombre del lugar *",
                  ),

                  DropdownButtonFormField(value: categoria,items: categorias.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        categoria = value!;
                      });
                    },
                    decoration:InputDecoration(labelText:"Categoría",
                      filled: true,
                      fillColor: Colors.white,
                      border:OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  campo(controller:ubicacionController,
                        label:"Ubicación",
                  ),

                  campo(
                    controller:telefonoController,
                    label:"Teléfono",
                  ),

                  campo(
                    controller:horarioController,
                    label:"Horario",
                  ),

                  campo(
                    controller:whatsappController,
                    label:"WhatsApp",
                  ),

                  campo(
                    controller:facebookController,
                    label:"Facebook URL",
                  ),

                  campo(
                    controller:mapsController,
                    label:"Google Maps URL",
                  ),

                  campo(
  controller: latitudController,
  label: "Latitud",
),

campo(
  controller: longitudController,
  label: "Longitud",
),

                  campo(
  controller: descripcionController,
  label:"Descripción",
  maxLines: 5,
),

                  if (imagenes.isNotEmpty)
  SizedBox(
    height: 120,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: imagenes.length,
      itemBuilder: (context, index) {

        return Container(
          margin: const EdgeInsets.only(
            right: 10,
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(15),
            child: Image.file(
              imagenes[index],
              width: 120,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    ),
  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width:double.infinity,
                    height: 55,
                    child:ElevatedButton.icon(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 219, 219, 218),
                      ),

                    onPressed: seleccionarImagenes,icon: const Icon(
                        Icons.image,
                      ),
                      label: const Text(
                        "Seleccionar imagenes",
                      ),
                    ),
                  ),
                  if (videos.isNotEmpty)
  SizedBox(
    height: 90,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: videos.length,
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
  const SizedBox(height: 15),

SizedBox(
  width: double.infinity,
  height: 55,
  child: ElevatedButton.icon(
    onPressed: seleccionarVideo,
    icon: const Icon(
      Icons.video_library,
    ),
    label: const Text(
      "Seleccionar video",
    ),
  ),
),

                  const SizedBox(
                      height: 20),
                  SizedBox(
                    width:
                        double.infinity,
                    height: 60,
                    child:
                        ElevatedButton.icon(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 204, 204, 203),
                      ),

                      onPressed:
                          cargando
                              ? null : subirLugar,
                      icon: cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload,),

                      label: Text(
                        cargando? "Subiendo...": "Publicar lugar",
                        style:const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}