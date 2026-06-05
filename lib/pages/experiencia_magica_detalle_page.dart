import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/video_player_widget.dart';
import '../widgets/texto_expandable.dart';
import '../utils/image_viewer_helper.dart';

class ExperienciaMagicaDetallePage extends StatelessWidget {
  final Map<String, dynamic> lugar;

  const ExperienciaMagicaDetallePage({
    super.key,
    required this.lugar,
  });

  Future<void> abrirUrl(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imagenes =
        List<String>.from(lugar['imagenes'] ?? []);

    final List<String> videos =
    List<String>.from(
      lugar['videos'] ?? [],
    );

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      body: CustomScrollView(
        slivers: [

          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,

            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [

                  imagenes.isNotEmpty
                      ? PageView.builder(
                          itemCount: imagenes.length,
                          itemBuilder: (_, index) {
                            return GestureDetector(
                              onTap: () {
                                ImageViewerHelper.abrir(
                                  context,
                                  images: imagenes,
                                  initialIndex: index,
                                );
                              },
                              child: Image.network(
                                imagenes[index],
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image,
                            size: 90,
                          ),
                        ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(.55),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    lugar['nombre'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if ((lugar['horario'] ?? '')
    .toString()
    .isNotEmpty) ...[
  const SizedBox(height: 6),

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
        color: const Color.fromARGB(
          255,
          85,
          84,
          82,
        ).withOpacity(0.25),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.access_time_filled,
          size: 12,
          color: Color.fromARGB(
            255,
            15,
            15,
            15,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            lugar['horario'],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  ),
],

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius:
                          BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.blue.shade100,
                      ),
                    ),
                    child: Text(
                      lugar['categoria'] ?? '',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextoExpandable(
                    texto:
                        lugar['descripcion'] ?? '',
                    maxLineas: 5,
                    fontSize: 15,
                  ),

                  const SizedBox(height: 30),

                  if (imagenes.isNotEmpty) ...[
                    const Text(
                      "Galería",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      height: 110,

                      child: ListView.builder(
                        scrollDirection:
                            Axis.horizontal,

                        itemCount: imagenes.length,

                        itemBuilder: (_, index) {

                          return GestureDetector(
                            onTap: () {
                              ImageViewerHelper.abrir(
                                context,
                                images: imagenes,
                                initialIndex: index,
                              );
                            },

                            child: Container(
                              width: 130,

                              margin:
                                  const EdgeInsets.only(
                                right: 12,
                              ),

                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),

                                boxShadow: const [
                                  BoxShadow(
                                    color:
                                        Colors.black12,
                                    blurRadius: 10,
                                    offset:
                                        Offset(0, 4),
                                  ),
                                ],
                              ),

                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),

                                child: Image.network(
                                  imagenes[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],

if (videos.isNotEmpty) ...[

  const Text(
    "Videos",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 15),

  Column(
    children: videos.map((video) {

      return Padding(
        padding: const EdgeInsets.only(
          bottom: 15,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(12),
          child: VideoPlayerWidget(
            videoUrl: video,
            aspectRatio: 16 / 9,
            borderRadius: 12,
          ),
        ),
      );

    }).toList(),
  ),

  const SizedBox(height: 30),
],

                  if ((lugar['ubicacion'] ?? '')
                      .toString()
                      .isNotEmpty)
                    infoTile(
                      Icons.location_on,
                      "Ubicación",
                      lugar['ubicacion'],
                    ),

                  const SizedBox(height: 30),

                  GridView.count(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisCount: 2,
  mainAxisSpacing: 10,
  crossAxisSpacing: 10,
  childAspectRatio: 3.2,
  children: [

    if ((lugar['whatsapp'] ?? '')
        .toString()
        .isNotEmpty)
      _cardEnlace(
        context: context,
        icon: Icons.chat,
        label: 'WhatsApp',
        color: Colors.green,
        onTap: () {
          abrirUrl(
            "https://wa.me/${lugar['whatsapp']}",
          );
        },
      ),

    if ((lugar['telefono'] ?? '')
    .toString()
    .isNotEmpty)
  _cardEnlace(
    context: context,
    icon: Icons.phone,
    label: 'Llamar',
    color: const Color.fromARGB(255, 115, 132, 163),
    onTap: () {
      abrirUrl(
        "tel:${lugar['telefono']}",
      );
    },
  ),

    if ((lugar['facebook'] ?? '')
        .toString()
        .isNotEmpty)
      _cardEnlace(
        context: context,
        icon: Icons.facebook,
        label: 'Facebook',
        color: Colors.blue,
        onTap: () {
          abrirUrl(
            lugar['facebook'],
          );
        },
      ),

    if ((lugar['maps_url'] ?? '')
        .toString()
        .isNotEmpty)
      _cardEnlace(
        context: context,
        icon: Icons.directions,
        label: 'Cómo llegar',
        color: const Color.fromARGB(255, 78, 78, 78),
        onTap: () {
          abrirUrl(
            lugar['maps_url'],
          );
        },
      ),
  ],
),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoTile(
  IconData icon,
  String titulo,
  String valor,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget botonAccion(
    IconData icon,
    String texto,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,

      icon: Icon(icon),

      label: Text(texto),

      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize:
            const Size(160, 55),

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),
    );
  }
  Widget _cardEnlace({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(.30),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
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
}