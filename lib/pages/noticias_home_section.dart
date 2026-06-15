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
    borderRadius: BorderRadius.circular(5),
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(3),
            ),
            child: Image.network(
              noticia['imagen'] ?? '',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A003C),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        noticia['categoria'] ??
                            'NOTICIAS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        noticia['fecha']
                            .toString()
                            .substring(0, 10),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 17, 17, 17),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  noticia['titulo'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  noticia['descripcion'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.4,
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

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
  color: Colors.transparent,
  borderRadius: const BorderRadius.vertical(
    top: Radius.circular(30),
  ),
),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),

          Center(
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 12,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF7A003C),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.20),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: const Text(
      "LUGARES MAGICOS",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),
  ),
),

          const SizedBox(height: 20),

          ...noticias.map(
            (n) => _cardNoticia(n),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}