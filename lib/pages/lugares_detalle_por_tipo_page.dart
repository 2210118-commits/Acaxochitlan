import 'package:flutter/material.dart';
import 'package:acaxochi/widgets/texto_expandable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/image_viewer_helper.dart';
import 'package:acaxochi/widgets/video_player_widget.dart';


class LugaresDetallePorTipoPage extends StatelessWidget {
  final Map<String, dynamic> lugar;

  const LugaresDetallePorTipoPage({
    super.key,
    required this.lugar,
  });

  Future<void> _abrirUrl(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception('No se pudo abrir $url');
  }
}
Widget _cardEnlace({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required String url,
}) {
  return InkWell(
    onTap: () => _abrirUrl(url),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final galeria = (lugar['galeria'] ?? []) as List;
    final videos = (lugar['videos'] ?? []) as List;
    final servicios = (lugar['servicios'] ?? []) as List;
    final actividades = (lugar['actividades'] ?? []) as List;
    final platillos = (lugar['platillos'] ?? []) as List;
    final recamaras = (lugar['recamaras'] ?? []) as List;
    final telefono = lugar['telefono'];
    final paginaWeb = lugar['pagina_web'];
    final facebook = lugar['facebook'];
    final latitud = lugar['latitud'];
    final longitud = lugar['longitud'];
    final logo = lugar['logo'];


    return Scaffold(
      appBar: AppBar(
        title: Text(lugar['nombre']),
      ),
      body: ListView(
        children: [
          /// 🖼️ IMAGEN PRINCIPAL
          if (lugar['imagen_principal'] != null)
            GestureDetector(
  onTap: () => ImageViewerHelper.abrir(
  context,
  images: [lugar['imagen_principal']],
  initialIndex: 0,
),

  child: Hero(
    tag: lugar['imagen_principal'],
    child: Image.network(
      lugar['imagen_principal'],
      height: 250,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  ),
),


          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
/// 🏷️ NOMBRE + LOGO
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    if (logo != null)
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            logo,
            height: 50,
            width: 50,
            fit: BoxFit.cover,
          ),
        ),
      ),

    Expanded(
      child: Text(
        lugar['nombre'] ?? '',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),


                /// 💲 PRECIO
                if (lugar['precio'] != null && lugar['tipo'] != 'restaurante')
  Text(
    '\$${lugar['precio']} por noche',
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.green,
    ),
  ),

                const SizedBox(height: 12),

                /// 📝 DESCRIPCIÓN
if (lugar['descripcion'] != null)
  TextoExpandable(
    texto: lugar['descripcion'],
    maxLineas: 3,
    fontSize: 16,
  ),


                const SizedBox(height: 20),

                /// 🖼️ GALERÍA
                if (galeria.isNotEmpty) ...[
                  const Text(
                    'Galería',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: galeria.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GestureDetector(
  onTap: () => ImageViewerHelper.abrir(
  context,
  images: List<String>.from(galeria),
  initialIndex: i,
),
  child: Hero(
    tag: galeria[i],
    child: Image.network(
      galeria[i],
      width: 160,
      fit: BoxFit.cover,
    ),
  ),
),

                        ),
                      ),
                    ),
                  ),
                ],

                /// 🎥 VIDEOS
/// 🎥 VIDEOS
if (videos.isNotEmpty) ...[
  const SizedBox(height: 20),

  const Text(
    'Videos',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 10),

  /// 🔥 SI SOLO ES 1 VIDEO
  if (videos.length == 1)
    VideoPlayerWidget(
      videoUrl: videos.first,
      aspectRatio: 16 / 9,
      borderRadius: 8, // más cuadrado
    )

  /// 🔥 SI SON 2 O MÁS
  else
    SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 200,
              child: VideoPlayerWidget(
                videoUrl: videos[index],
                aspectRatio: 4 / 5,
                borderRadius: 0,
              ),
            ),
          );
        },
      ),
    ),
],


                /// 🧰 SERVICIOS
                if (servicios.isNotEmpty) ...[
                  const Text(
                    'Servicios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: servicios
                        .map((s) => Chip(label: Text(s)))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                /// 🎯 ACTIVIDADES
                if (actividades.isNotEmpty) ...[
                  const Text(
                    'Actividades',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: actividades
                        .map((a) => Chip(label: Text(a)))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                /// 🛏️ RECÁMARAS
if (recamaras.isNotEmpty) ...[

  ...recamaras.map((r) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r['imagen'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: GestureDetector(
  onTap: () => ImageViewerHelper.abrir(
  context,
  images: [r['imagen']],
  initialIndex: 0,
),
  child: Hero(
    tag: r['imagen'],
    child: Image.network(
      r['imagen'],
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  ),
),

              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r['nombre'] != null)
                    Text(
                      r['nombre'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  if (r['precio'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '\$${r['precio']}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      )),

  const SizedBox(height: 20),
],

                /// 🍽️ PLATILLOS
                if (platillos.isNotEmpty) ...[
                  const Text(
                    'Platillos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: platillos.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2, // 🔥 2 por fila
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 0.85,
  ),
  itemBuilder: (_, i) {
    final p = platillos[i];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p['imagen'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: GestureDetector(
  onTap: () => ImageViewerHelper.abrir(
  context,
  images: [p['imagen']],
  initialIndex: 0,
),

  child: Hero(
    tag: p['imagen'],
    child: Image.network(
      p['imagen'],
      height: 100,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  ),
),

            ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['nombre'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (p['precio'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '\$${p['precio']}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  },
),

                  const SizedBox(height: 20),
                ],

                /// 🌐 Enlaces y ubicación
if (
  (paginaWeb != null && paginaWeb.toString().isNotEmpty) ||
  (facebook != null && facebook.toString().isNotEmpty) ||
  (telefono != null && telefono.toString().isNotEmpty) ||
  (latitud != null && longitud != null)
) ...[
  const SizedBox(height: 30),

  const Text(
    'Enlaces',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
  const SizedBox(height: 12),

  GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 3.2,
    children: [

      /// Teléfono
if (telefono != null && telefono.toString().isNotEmpty)
  _cardEnlace(
    context: context,
    icon: Icons.phone,
    label: telefono,
    color: Colors.green,
    url: "tel:$telefono",
  ),

      /// Página web
      if (paginaWeb != null && paginaWeb.toString().isNotEmpty)
        _cardEnlace(
          context: context,
          icon: Icons.language,
          label: "Página web",
          color: Colors.blueGrey,
          url: paginaWeb,
        ),

      /// Facebook
      if (facebook != null && facebook.toString().isNotEmpty)
        _cardEnlace(
          context: context,
          icon: Icons.facebook,
          label: "Facebook",
          color: Colors.blue,
          url: facebook,
        ),
    ],
  ),
  /// 🗺️ Cómo llegar
if (latitud != null && longitud != null) ...[
  const SizedBox(height: 20),

  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        _abrirUrl(
          "https://www.google.com/maps/dir/?api=1&destination=$latitud,$longitud",
        );
      },
      icon: const Icon(Icons.directions),
      label: const Text("Cómo llegar"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  ),
],
],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
