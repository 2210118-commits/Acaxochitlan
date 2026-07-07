import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'noticia_detalle_page.dart';

class NoticiasHomeSection extends StatefulWidget {
  const NoticiasHomeSection({super.key});

  @override
  State<NoticiasHomeSection> createState() =>
      _NoticiasHomeSectionState();
}

class _NoticiasHomeSectionState
    extends State<NoticiasHomeSection> {
  List<dynamic> noticias = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarNoticias();
  }

  Future<void> cargarNoticias() async {
  try {
    print("🚀 CONSULTANDO NOTICIAS");

    final response = await Supabase.instance.client
        .from('noticias')
        .select()
        .order('fecha', ascending: false)
        .limit(5);

    print("🔥 NOTICIAS: $response");

    if (!mounted) return;

    setState(() {
      noticias = response;
      cargando = false;
    });
  } catch (e) {
    print("❌ ERROR NOTICIAS: $e");

    if (!mounted) return;

    setState(() {
      cargando = false;
    });
  }
}

  Widget _cardNoticia(Map noticia) {
  return InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoticiaDetallePage(
            noticia: noticia,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(right: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [

            /// FOTO
            Image.network(
              noticia["imagen"] ?? "",
              fit: BoxFit.cover,
            ),

            /// DEGRADADO
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(.85),
                  ],
                ),
              ),
            ),

            /// TEXTO
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    noticia["titulo"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    noticia["descripcion"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Row(
                    children: [

                      Text(
                        "Ver más",
                        style: TextStyle(
                          color: Color(0xffD8A72C),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      SizedBox(width: 6),

                      Icon(
                        Icons.arrow_forward,
                        color: Color(0xffD8A72C),
                        size: 18,
                      )

                    ],
                  )

                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  if (cargando) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  return SizedBox(
    height: 330,

    child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: noticias.length,

      itemBuilder: (context, index) {
        final noticia = noticias[index];

        return SizedBox(
          width: 320,
          child: _cardNoticia(noticia),
        );
      },
    ),
  );
}
}