import 'package:flutter/material.dart';
import '../utils/image_viewer_helper.dart';
import 'package:acaxochi/widgets/texto_expandable.dart';
import '../widgets/video_player_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'editar_tienda_hidarte_page.dart';
import '../widgets/bottom_nav.dart';

class DetalleTiendaHidartePage extends StatelessWidget {
  final Map<String, dynamic> producto;

  const DetalleTiendaHidartePage({
    super.key,
    required this.producto,
  });

  String _fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('/object/public/')) return url;
    if (url.contains('/object/sign/')) {
      return url.replaceFirst('/object/sign/', '/object/public/');
    }
    return url;
  }

  List _safeList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    return [];
  }

  Future<void> _abrirUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'No se pudo abrir $url';
  }
}

Future<void> _llamar(String telefono) async {
  final Uri uri = Uri.parse('tel:$telefono');
  await launchUrl(uri);
}

Future<void> _abrirMapa(double lat, double lng) async {
  final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  await _abrirUrl(url);
}

  @override
  Widget build(BuildContext context) {
    final imagen = _fixImageUrl(producto['imagen_principal']);

    final List galeria = _safeList(producto['galeria']);
    final List videos = _safeList(producto['videos']);
    final List productos = _safeList(producto['productos']);
    final paginaWeb = producto['pagina_web']?.toString() ?? '';
final facebook = producto['facebook']?.toString() ?? '';
final telefono = producto['telefono']?.toString() ?? '';

final lat = producto['latitud'];
final lng = producto['longitud'];

    return Scaffold(
      bottomNavigationBar: const BottomNav(
  currentIndex: 2,
),
      appBar: AppBar(
  title: Text(producto['nombre'] ?? 'Detalle'),
  actions: [
    if (Supabase.instance.client.auth.currentUser != null)
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          final actualizado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EditarTiendaHidartePage(producto: producto),
            ),
          );

          if (actualizado == true) {
            Navigator.pop(context, true);
          }
        },
      ),
  ],
),
      body: ListView(
        children: [

          /// 🖼️ IMAGEN PRINCIPAL
          if (imagen.isNotEmpty)
            GestureDetector(
              onTap: () => ImageViewerHelper.abrir(
                context,
                images: [imagen],
                initialIndex: 0,
              ),
              child: Hero(
                tag: imagen,
                child: Image.network(
                  imagen,
                  height: 260,
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

                /// 🏷️ NOMBRE
                Text(
                  producto['nombre'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                /// 📝 DESCRIPCIÓN
                if (producto['descripcion'] != null)
                  TextoExpandable(
                    texto: producto['descripcion'],
                    maxLineas: 4,
                    fontSize: 12,
                  ),

                const SizedBox(height: 20),

                /// 📦 STOCK
                if (producto['stock'] != null)
                  Text(
                    'Stock: ${producto['stock']}',
                    style: const TextStyle(fontSize: 16),
                  ),

                const SizedBox(height: 10),

                /// 🏷️ CATEGORÍA
                if (producto['categoria'] != null)
                  Chip(label: Text(producto['categoria'])),

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
  const SizedBox(height: 12),

  SizedBox(
    height: 180,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: galeria.length,
      itemBuilder: (context, i) {
        final item = galeria[i];
        final img = _fixImageUrl(item['url']);

        return GestureDetector(
          onTap: () => ImageViewerHelper.abrir(
            context,
            images: galeria
                .map<String>((e) => _fixImageUrl(e['url']))
                .toList(),
            initialIndex: i,
          ),

          child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  /// 🖼️ IMAGEN
                  Positioned.fill(
                    child: Image.network(
                      img,
                      fit: BoxFit.cover,
                    ),
                  ),

                  /// 🌑 GRADIENTE PARA TEXTO
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black54,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  /// 📝 DESCRIPCIÓN
                  if (item['descripcion'] != null)
                    Positioned(
                      bottom: 6,
                      left: 8,
                      right: 8,
                      child: Text(
                        item['descripcion'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
],

                const SizedBox(height: 20),

                /// 🎥 VIDEOS 
if (videos.isNotEmpty) ...[
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
    AspectRatio(
      aspectRatio: 16 / 9,
      child: VideoPlayerWidget(
        videoUrl: _fixImageUrl(videos.first),
      ),
    )

  /// 🔥 SI HAY VARIOS (SCROLL HORIZONTAL)
  else
    SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final url = _fixImageUrl(videos[index]);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 200,
              child: VideoPlayerWidget(
                videoUrl: url,
              ),
            ),
          );
        },
      ),
    ),
],

                const SizedBox(height: 10),

                /// 🛍️ PRODUCTOS
if (productos.isNotEmpty) ...[
  const Text(
    'Productos',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 10),

  GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: productos.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 3,
      mainAxisSpacing: 3,
      childAspectRatio: 0.72,
    ),
    itemBuilder: (context, index) {
      final p = productos[index];
      final img = _fixImageUrl(p['imagen']);

      return GestureDetector(
        onTap: () {
          if (img.isNotEmpty) {
            ImageViewerHelper.abrir(
              context,
              images: [img],
              initialIndex: 0,
            );
          }
        },
        child: Card(
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [

              Expanded(
                flex: 7,
                child: img.isNotEmpty
                    ? Image.network(
                        img,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image_outlined),
                        ),
                      ),
              ),

              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 2,
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        p['nombre'] ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),

                      if (p['precio'] != null)
                        Text(
                          '\$${p['precio']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
],

                const SizedBox(height: 30),

              
if (paginaWeb.isNotEmpty ||
    facebook.isNotEmpty ||
    telefono.isNotEmpty) ...[

  const Text(
    'Contacto',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 10),

  Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [

      /// 🌐 WEB
      if (paginaWeb.isNotEmpty)
        _botonAccion(
          icon: Icons.language,
          label: 'Sitio Web',
          color: Colors.blue,
          onTap: () => _abrirUrl(paginaWeb),
        ),

      /// 👍 FACEBOOK
      if (facebook.isNotEmpty)
        _botonAccion(
          icon: Icons.facebook,
          label: 'Facebook',
          color: Colors.indigo,
          onTap: () => _abrirUrl(facebook),
        ),

      /// 📞 TELÉFONO
      if (telefono.isNotEmpty)
        _botonAccion(
          icon: Icons.phone,
          label: 'Llamar',
          color: Colors.green,
          onTap: () => _llamar(telefono),
        ),
    ],
  ),

  const SizedBox(height: 20),

],      
                
                const SizedBox(height: 10),

          
if (lat != null && lng != null && lat != 0 && lng != 0) ...[
  
  const Text(
    'Ubicación',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 10),

  Center(
  child: SizedBox(
    width: 200,
    child: _botonAccion(
      icon: Icons.location_on,
      label: 'Cómo llegar',
      color: const Color.fromRGBO(141, 205, 207, 1),
      onTap: () => _abrirMapa(
        producto['latitud'],
        producto['longitud'],
      ),
    ),
  ),
),

  const SizedBox(height: 20),
],
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _botonAccion({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
}