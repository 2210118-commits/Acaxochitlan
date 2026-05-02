import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AgregarLugarPage extends StatefulWidget {
  const AgregarLugarPage({super.key});

  @override
  State<AgregarLugarPage> createState() => _AgregarLugarPageState();
}

class _AgregarLugarPageState extends State<AgregarLugarPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  final TextEditingController latitudController = TextEditingController();
  final TextEditingController longitudController = TextEditingController();

  final TextEditingController actividadController = TextEditingController();
  final TextEditingController restauranteController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  File? imagenPrincipal;
  List<File> imagenesExtras = [];
  List<File> videos = [];

  List<String> actividades = [];
  List<String> restaurantes = [];

  // ---------------- IMAGEN PRINCIPAL ----------------
  Future<void> seleccionarImagenPrincipal() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        imagenPrincipal = File(image.path);
      });
    }
  }

  // ---------------- VARIAS IMÁGENES ----------------
  Future<void> seleccionarImagenesExtras() async {
    final List<XFile> images = await _picker.pickMultiImage();

    setState(() {
      imagenesExtras.addAll(images.map((e) => File(e.path)));
    });
  }

  // ---------------- VIDEOS ----------------
  Future<void> seleccionarVideo() async {
    final XFile? video =
        await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      setState(() {
        videos.add(File(video.path));
      });
    }
  }

  // ---------------- AGREGAR ACTIVIDAD ----------------
  void agregarActividad() {
    if (actividadController.text.isNotEmpty) {
      setState(() {
        actividades.add(actividadController.text);
        actividadController.clear();
      });
    }
  }

  // ---------------- AGREGAR RESTAURANTE ----------------
  void agregarRestaurante() {
    if (restauranteController.text.isNotEmpty) {
      setState(() {
        restaurantes.add(restauranteController.text);
        restauranteController.clear();
      });
    }
  }

  // ---------------- GUARDAR ----------------
  void guardarLugar() {
    if (nombreController.text.isEmpty ||
        imagenPrincipal == null ||
        latitudController.text.isEmpty ||
        longitudController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nombre, imagen principal y coordenadas son obligatorios"),
        ),
      );
      return;
    }

    double lat = double.parse(latitudController.text);
    double lng = double.parse(longitudController.text);

    print("Nombre: ${nombreController.text}");
    print("Latitud: $lat");
    print("Longitud: $lng");
    print("Actividades: $actividades");
    print("Restaurantes: $restaurantes");

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar Lugar Turístico"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // NOMBRE
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre del lugar *",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // DESCRIPCIÓN
            TextField(
              controller: descripcionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // ACTIVIDADES
            const Text(
              "Actividades",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: actividadController,
                    decoration: const InputDecoration(
                      labelText: "Nueva actividad",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: agregarActividad,
                )
              ],
            ),
            Wrap(
              spacing: 8,
              children: actividades
                  .map((act) => Chip(
                        label: Text(act),
                        onDeleted: () {
                          setState(() {
                            actividades.remove(act);
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // RESTAURANTES
            const Text(
              "Restaurantes / Puestos",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: restauranteController,
                    decoration: const InputDecoration(
                      labelText: "Nuevo restaurante o puesto",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: agregarRestaurante,
                )
              ],
            ),
            Wrap(
              spacing: 8,
              children: restaurantes
                  .map((res) => Chip(
                        label: Text(res),
                        onDeleted: () {
                          setState(() {
                            restaurantes.remove(res);
                          });
                        },
                      ))
                  .toList(),
            ),

            const SizedBox(height: 30),

            // COORDENADAS
            const Text(
              "Ubicación (Coordenadas) *",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: latitudController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Latitud",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: longitudController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Longitud",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // BOTÓN GUARDAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: guardarLugar,
                child: const Text("Guardar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
