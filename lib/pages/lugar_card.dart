import 'package:flutter/material.dart';
import 'lugares_detalle_por_tipo_page.dart';
import 'detalle_festividad_page.dart';
import 'actividades_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LugarCard extends StatelessWidget {

  final Map<String, dynamic> lugar;

  const LugarCard({
    super.key,
    required this.lugar,
  });

  @override
  Widget build(BuildContext context) {

    final imagen = lugar['imagen_principal'];
    final esVideo = lugar['es_video'] == true;
    final nombre = lugar['nombre'] ?? '';
    final descripcion = lugar['descripcion'] ?? '';
    final precio = lugar['precio'];
    final categoria = lugar['categoria'] ?? '';
    final galeria = lugar['galeria'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),

        child: Material(
          color: Colors.white,

          child: InkWell(

            onTap: () {

  if (lugar["origen"] == "festividades") {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleFestividadPage(
          festividad: lugar,
        ),
      ),
    );

  } else if (lugar["origen"] == "actividades") {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ActividadesPage(),
      ),
    );

  } else {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LugaresDetallePorTipoPage(
          lugar: lugar,
        ),
      ),
    );
  }
},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// IMAGEN PRINCIPAL
                Stack(
                  children: [

                    imagen != null && imagen.toString().isNotEmpty
    ? esVideo
        ? Stack(
            children: [

              /// 🔥 THUMBNAIL DEL VIDEO
              SizedBox(
                height: 180,
                width: double.infinity,
                child: VideoItem(url: imagen),
              ),

              /// ▶️ ICONO PLAY
              const Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )
        : Image.network(
            imagen,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                height: 180,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              );
            },
          )
    : Container(
        height: 180,
        color: Colors.grey[300],
        child: const Icon(Icons.image),
      ),

                    /// degradado
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    /// categoria
                    if (categoria.isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            categoria,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                /// INFORMACION
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// nombre
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// descripcion
                      if (descripcion.toString().isNotEmpty)
                        Text(
                          descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),

                      const SizedBox(height: 10),

                      /// GALERIA MINIATURA
                      if (galeria != null && galeria.isNotEmpty)
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: galeria.length > 3 ? 3 : galeria.length,
                            itemBuilder: (context, index) {

                              final img = galeria[index];

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    img,
                                    width: 70,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Container(
                                        width: 70,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [

                          /// precio
                          if (precio != null &&
                              precio.toString().isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                Text(
                                  precio.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),

                          /// boton
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  "Ver más",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 16,
                                )
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}