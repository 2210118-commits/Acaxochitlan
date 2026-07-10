import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'noticia_detalle_page.dart';
import '../utils/noticias_cache.dart';

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

  if (NoticiasCache.noticias != null) {
    setState(() {
      noticias = NoticiasCache.noticias!;
      cargando = false;
    });
    return;
  }

  try {
    final response = await Supabase.instance.client
        .from('noticias')
        .select()
        .order('fecha', ascending: false)
        .limit(5);

    if (!mounted) return;

    NoticiasCache.noticias = response;

    setState(() {
      noticias = response;
      cargando = false;
    });

  } catch (e) {

    if (!mounted) return;

    setState(() {
      cargando = false;
    });
  }
}
  Widget _cardNoticia(Map noticia) {
  return InkWell(
    borderRadius: BorderRadius.circular(8),
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
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
                    Colors.black.withOpacity(.55),
                  ],
                ),
              ),
            ),

            /// TEXTO
            Positioned(
              left: 2,
              right: 2,
              bottom: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    noticia["titulo"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    noticia["descripcion"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: .9,
                    ),
                  ),

                  const SizedBox(height: 3),
                  SizedBox(width: 10),

                  const Row(
                    children: [

                      Text(
                        "Ver más",
                        style: TextStyle(
                          color: Color.fromARGB(255, 243, 212, 34),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),

                      SizedBox(width: 6),

                      Icon(
                        Icons.arrow_forward,
                        color: Color.fromARGB(255, 243, 212, 34),
                        size: 16,
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
  final size = MediaQuery.of(context).size;
  if (cargando) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  return SizedBox(
    height: size.height * 0.16,//ALTURA DEL CARDNOTICIAS

    child: ListView.builder(
      padding: EdgeInsets.symmetric(
  horizontal: size.width * 0.05,
),
      scrollDirection: Axis.horizontal,
      itemCount: noticias.length,

      itemBuilder: (context, index) {
        final noticia = noticias[index];
//ANCHO DEL CARD NOTICIAS
        return SizedBox(
          width: size.width * 0.30,
          child: _cardNoticia(noticia),
        );
      },
    ),
  );
}
}