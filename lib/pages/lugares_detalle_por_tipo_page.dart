import 'package:flutter/material.dart';
import 'package:acaxochi/widgets/texto_expandable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/image_viewer_helper.dart';
import 'package:acaxochi/widgets/video_player_widget.dart';
import '../widgets/bottom_nav.dart';
//PARA REDUCCION DE CAHED EGRESS
import 'package:cached_network_image/cached_network_image.dart';
import '../cache/custom_cache_manager.dart';
import '../utils/media_optimizer.dart';

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
    final galeria = List<String>.from(lugar['galeria'] ?? []);
    final platillos = List<Map<String, dynamic>>.from(
      lugar['platillos'] ?? [],
    );
    final recamaras = List<Map<String, dynamic>>.from(
      lugar['recamaras'] ?? [],
    );
    final videos = (lugar['videos'] ?? []) as List;
    final servicios = (lugar['servicios'] ?? []) as List;
    final actividades = (lugar['actividades'] ?? []) as List;
    final telefono = lugar['telefono'];
    final paginaWeb = lugar['pagina_web'];
    final facebook = lugar['facebook'];
    final whatsapp = lugar['whatsapp'];
    final horario = lugar['horario'];
    final latitud = lugar['latitud'];
    final longitud = lugar['longitud'];
    final logo = lugar['logo'];

    return Scaffold(
      bottomNavigationBar: const BottomNav(
        currentIndex: 0,
      ),
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
                child: CachedNetworkImage(
                  cacheManager: CustomCacheManager.instance,
                  imageUrl: MediaOptimizer.fullscreen(
                    lugar['imagen_principal'],
                  ),
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: 1200,
                  memCacheHeight: 700,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                )),

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
                            child: CachedNetworkImage(
                              cacheManager: CustomCacheManager.instance,
                              imageUrl: MediaOptimizer.thumbnail(logo),
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (_, __, ___) {
                                return const Icon(Icons.store);
                              },
                            )),
                      ),
                    Expanded(
                      child: Text(
                        lugar['nombre'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                if (horario != null && horario.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 97, 95, 91)
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: const Color.fromARGB(255, 85, 84, 82)
                            .withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          size: 12,
                          color: Color.fromARGB(255, 15, 15, 15),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            horario,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                /// 💲 PRECIO
                if (lugar['precio'] != null &&
                    lugar['precio'].toString().trim().isNotEmpty &&
                    lugar['tipo'] != 'restaurante')
                  Text(
                    lugar['precio'],
                    style: const TextStyle(
                      fontSize: 12,
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
                    fontSize: 12,
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
                              child: CachedNetworkImage(
                                cacheManager: CustomCacheManager.instance,
                                imageUrl: MediaOptimizer.galeria(galeria[i]),
                                width: 160,
                                fit: BoxFit.cover,
                                memCacheWidth: 400,
                                memCacheHeight: 300,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

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
                const SizedBox(height: 10),

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
                    children:
                        servicios.map((s) => Chip(label: Text(s))).toList(),
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
                    children:
                        actividades.map((a) => Chip(label: Text(a))).toList(),
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
                                  top: Radius.circular(3),
                                ),
                                child: GestureDetector(
                                    onTap: () => ImageViewerHelper.abrir(
                                          context,
                                          images: [r['imagen']],
                                          initialIndex: 0,
                                        ),
                                    child: CachedNetworkImage(
                                      cacheManager: CustomCacheManager.instance,
                                      imageUrl:
                                          MediaOptimizer.galeria(r['imagen']),
                                      height: 170,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 600,
                                      memCacheHeight: 400,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    )),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(1),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (r['nombre'] != null)
                                    Text(
                                      r['nombre'],
                                      style: const TextStyle(
                                        fontSize: 14,
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: platillos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (_, i) {
                      final p = platillos[i];

                      final tieneImagen = p['imagen'] != null &&
                          p['imagen'].toString().isNotEmpty;

                      final tieneNombre = p['nombre'] != null &&
                          p['nombre'].toString().isNotEmpty;

                      final tienePrecio = p['precio'] != null;

                      return Card(
                        elevation: 1,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            /// IMAGEN
                            if (tieneImagen)
                              Expanded(
                                child: GestureDetector(
                                    onTap: () => ImageViewerHelper.abrir(
                                          context,
                                          images: [p['imagen'].toString()],
                                          initialIndex: 0,
                                        ),
                                    child: CachedNetworkImage(
                                      cacheManager: CustomCacheManager.instance,
                                      imageUrl:
                                          MediaOptimizer.thumbnail(p['imagen']),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 400,
                                      memCacheHeight: 400,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    )),
                              ),

                            /// SOLO SI EXISTE NOMBRE O PRECIO
                            if (tieneNombre || tienePrecio)
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  children: [
                                    if (tieneNombre)
                                      Text(
                                        p['nombre'],
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (tienePrecio)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '\$${p['precio']}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
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
                if ((paginaWeb != null && paginaWeb.toString().isNotEmpty) ||
                    (facebook != null && facebook.toString().isNotEmpty) ||
                    (telefono != null && telefono.toString().isNotEmpty) ||
                    (whatsapp != null && whatsapp.toString().isNotEmpty) ||
                    (latitud != null && longitud != null)) ...[
                  const SizedBox(height: 30),

                  const Text(
                    'Enlaces',
                    style: TextStyle(
                      fontSize: 14,
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

                      if (whatsapp != null && whatsapp.toString().isNotEmpty)
                        _cardEnlace(
                          context: context,
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: Colors.green,
                          url: 'https://wa.me/$whatsapp',
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
                    const SizedBox(height: 14),
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
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
