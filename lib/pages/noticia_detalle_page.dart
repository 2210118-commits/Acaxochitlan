import 'package:flutter/material.dart';
import '../utils/image_viewer_helper.dart';
import '../widgets/video_player_widget.dart';
import 'package:url_launcher/url_launcher.dart';


class NoticiaDetallePage extends StatelessWidget {
  final Map noticia;

  const NoticiaDetallePage({
    super.key,
    required this.noticia,
  });

  @override
  Widget build(BuildContext context) {
    final imagen = noticia['imagen']?.toString() ?? '';
    final titulo = noticia['titulo'] ?? '';
    final descripcion = noticia['descripcion'] ?? '';
    final categoria = noticia['categoria'] ?? 'Noticias';

    final fecha =
        noticia['fecha']
                ?.toString()
                .substring(0, 10) ??
            '';

    final List galeria =
        noticia['galeria'] ?? [];

    final List videos =
        noticia['videos'] ?? [];

     final List<String> todasLasImagenes = [
  if (imagen.isNotEmpty) imagen,
  ...galeria
      .map<String>((e) => e['imagen'].toString())
      .toList(),
];
            return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF7A003C),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  imagen.isNotEmpty
    ? GestureDetector(
        onTap: () {
          ImageViewerHelper.abrir(
            context,
            images: todasLasImagenes,
            initialIndex: 0,
          );
        },
        child: Image.network(
          imagen,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) {
            return Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 70,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      )
    : Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(
            Icons.image,
            size: 70,
            color: Colors.grey,
          ),
        ),
      ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 30,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF7A003C,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            categoria,
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          titulo,
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color:
                                  Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              fecha,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white70,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(
                        0.08,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Descripción",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    if (galeria.isNotEmpty) ...[
                      const SizedBox(height: 40),

                     //GALERIA CON DESCRIPCION

                      ...galeria.map((item) {
                        return Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Colors.grey.shade50,
                            borderRadius:
                                BorderRadius.circular(5,),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(
                                  0.10,
                                ),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              ClipRRect(
                                borderRadius:
                                    const BorderRadius.vertical(
                                  top:
                                      Radius.circular(5,),
                                ),
                                child: GestureDetector(
  onTap: () {
    final index = galeria.indexOf(item) + 1;

    ImageViewerHelper.abrir(
      context,
      images: todasLasImagenes,
      initialIndex: index,
    );
  },
  child: Image.network(
    item['imagen'],
    height: 220,
    width: double.infinity,
    fit: BoxFit.cover,
  ),
),
                              ),

                              Padding(
                                padding:
                                    const EdgeInsets.all(
                                  4,
                                ),
                                child: Text(
                                  item['descripcion'] ??
                                      '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors
                                        .grey
                                        .shade800,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],

                    if (videos.isNotEmpty) ...[
                      const SizedBox(height: 10),

                      //videos

                      ...videos.map((video) {
  return Padding(
    padding: const EdgeInsets.only(
      bottom: 15,
    ),
    child: VideoPlayerWidget(
      videoUrl: video.toString(),
      aspectRatio: 4 / 3,
      borderRadius: 6,
    ),
  );
}).toList(),
                    ],

                    const SizedBox(height: 50),

                    ElevatedButton.icon(
  onPressed: () async {
    final lat = noticia['latitud'];
    final lng = noticia['longitud'];

    final url =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    launchUrl(Uri.parse(url));
  },
  icon: const Icon(Icons.directions),
  label: const Text('Cómo llegar'),
)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}