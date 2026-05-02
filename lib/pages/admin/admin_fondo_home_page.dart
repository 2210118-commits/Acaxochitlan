import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminFondoHomePage extends StatefulWidget {
  const AdminFondoHomePage({super.key});

  @override
  State<AdminFondoHomePage> createState() => _AdminFondoHomePageState();
}

class _AdminFondoHomePageState extends State<AdminFondoHomePage> {

  File? imagenSeleccionada;
  String? imagenActualUrl;
  String? imagenActualPath;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    obtenerFondoActual();
  }

  // 📥 OBTENER IMAGEN ACTUAL
  Future<void> obtenerFondoActual() async {
    final res = await Supabase.instance.client
        .from('config_app')
        .select()
        .eq('id', 1)
        .single();

    setState(() {
      imagenActualUrl = res['fondo_home'];
      imagenActualPath = res['fondo_home_path'];
    });
  }

  // 📸 SELECCIONAR IMAGEN
  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();

    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imagenSeleccionada = File(pickedFile.path);
      });
    }
  }

  // 🚀 SUBIR IMAGEN
  Future<void> subirImagen() async {

    if (imagenSeleccionada == null) return;

    setState(() => cargando = true);

    try {

      final fileName =
          'home_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 🗑️ ELIMINAR ANTERIOR SI EXISTE
      if (imagenActualPath != null) {
        await Supabase.instance.client.storage
            .from('fondos')
            .remove([imagenActualPath!]);
      }

      // 📤 SUBIR NUEVA
      await Supabase.instance.client.storage
          .from('fondos')
          .upload(fileName, imagenSeleccionada!);

      final url = Supabase.instance.client.storage
          .from('fondos')
          .getPublicUrl(fileName);

      // 💾 GUARDAR EN BD
      await Supabase.instance.client
          .from('config_app')
          .update({
        'fondo_home': url,
        'fondo_home_path': fileName,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', 1);

      setState(() {
        imagenActualUrl = url;
        imagenActualPath = fileName;
        imagenSeleccionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Fondo actualizado")),
      );

    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al subir")),
      );
    }

    setState(() => cargando = false);
  }

  // 🗑️ ELIMINAR FONDO
  Future<void> eliminarFondo() async {

    setState(() => cargando = true);

    try {

      if (imagenActualPath != null) {
        await Supabase.instance.client.storage
            .from('fondos')
            .remove([imagenActualPath!]);
      }

      await Supabase.instance.client
          .from('config_app')
          .update({
        'fondo_home': null,
        'fondo_home_path': null
      }).eq('id', 1);

      setState(() {
        imagenActualUrl = null;
        imagenSeleccionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Fondo eliminado")),
      );

    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al eliminar")),
      );
    }

    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fondo Home"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "Imagen actual",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // 🖼️ IMAGEN ACTUAL
            if (imagenActualUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imagenActualUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Text("No hay imagen"),

            const SizedBox(height: 25),

            const Divider(),

            const SizedBox(height: 15),

            const Text(
              "Nueva imagen",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // 👀 PREVIEW
            if (imagenSeleccionada != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imagenSeleccionada!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            // 📸 BOTÓN SELECCIONAR
            ElevatedButton.icon(
              onPressed: seleccionarImagen,
              icon: const Icon(Icons.photo),
              label: const Text("Seleccionar imagen"),
            ),

            const SizedBox(height: 10),

            // 🚀 SUBIR
            ElevatedButton.icon(
              onPressed: subirImagen,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Subir / Reemplazar"),
            ),

            const SizedBox(height: 10),

            // 🗑️ ELIMINAR
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: eliminarFondo,
              icon: const Icon(Icons.delete),
              label: const Text("Eliminar fondo"),
            ),

            const SizedBox(height: 20),

            if (cargando)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}