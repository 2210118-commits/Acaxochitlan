import 'package:flutter/material.dart';
import 'lugares_detalle_por_tipo_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'EditarLugarPage.dart';
import 'favoritos_service.dart';

class LugaresPorTipoPage extends StatefulWidget {
  final String tipo; // 'hotel' o 'cabana'
  final String titulo;

  const LugaresPorTipoPage({
    super.key,
    required this.tipo,
    required this.titulo,
  });

  @override
  State<LugaresPorTipoPage> createState() => _LugaresPorTipoPageState();
}

class _LugaresPorTipoPageState extends State<LugaresPorTipoPage> {
  Future<List<dynamic>>? _future;

  bool isAdmin = false;

  
@override
void initState() {
  super.initState();
  _verificarAdmin();
  _future = _cargarLugares();
}

  Future<List<dynamic>> _cargarLugares() async {
    final response = await Supabase.instance.client
        .from('lugares')
        .select()
        .eq('tipo', widget.tipo)
        .order('orden', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false);

    return response;
  }

  Future<void> _verificarAdmin() async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null || user.email == null) {
    setState(() => isAdmin = false);
    return;
  }

  try {
    final response = await Supabase.instance.client
        .from('admin_profiles')
        .select('email')
        .eq('email', user.email!)
        .maybeSingle();

    setState(() {
      isAdmin = response != null;
    });

    print("Usuario logueado: ${user.email}");
    print("Es admin?: $isAdmin");

  } catch (e) {
    setState(() => isAdmin = false);
  }
}

  Future<void> _eliminarLugar(Map<String, dynamic> lugar) async {
  try {

    // 1️⃣ Eliminar archivos
    await _eliminarArchivosStorage(lugar);

    // 2️⃣ Eliminar registro
    await Supabase.instance.client
        .from('lugares')
        .delete()
        .eq('id', lugar['id']);

    setState(() {
      _future = _cargarLugares();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lugar eliminado completamente')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al eliminar: $e')),
    );
  }
}
Future<void> _cambiarOrden(
  Map<String, dynamic> lugar,
) async {
  int? nuevoOrden;

  await showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text(
          'Orden de ${lugar['nombre']}',
        ),
        content: DropdownButtonFormField<int>(
          items: List.generate(
            70,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text('Posición ${i + 1}'),
            ),
          ),
          onChanged: (v) {
            nuevoOrden = v;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (nuevoOrden != null) {
                await Supabase.instance.client
                    .from('lugares')
                    .update({
                      'orden': nuevoOrden,
                    })
                    .eq('id', lugar['id']);
              }

              Navigator.pop(context);

              setState(() {
                _future = _cargarLugares();
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
Future<void> _eliminarArchivosStorage(Map<String, dynamic> lugar) async {
  final storage = Supabase.instance.client.storage.from('hoteles_cabanas');

  List<String> urls = [];

  // Imagen principal
  if (lugar['imagen_principal'] is String) {
    urls.add(lugar['imagen_principal']);
  }

  // Logo
  if (lugar['logo'] is String) {
    urls.add(lugar['logo']);
  }

  // Galería (List<String>)
  if (lugar['galeria'] is List) {
    for (var g in lugar['galeria']) {
      if (g is String) {
        urls.add(g);
      }
    }
  }

  // Videos (List<Map>)
  if (lugar['videos'] is List) {
    for (var v in lugar['videos']) {
      if (v is Map<String, dynamic>) {
        if (v['url'] is String) {
          urls.add(v['url']);
        }
        if (v['thumbnail'] is String) {
          urls.add(v['thumbnail']);
        }
      }
    }
  }

  // Recámaras
  if (lugar['recamaras'] is List) {
    for (var r in lugar['recamaras']) {
      if (r is Map<String, dynamic>) {
        if (r['imagen'] is String) {
          urls.add(r['imagen']);
        }
      }
    }
  }

  // Platillos
  if (lugar['platillos'] is List) {
    for (var p in lugar['platillos']) {
      if (p is Map<String, dynamic>) {
        if (p['imagen'] is String) {
          urls.add(p['imagen']);
        }
      }
    }
  }

  for (String url in urls) {
    try {
      final path = Uri.parse(url).pathSegments.skip(1).join('/');
      await storage.remove([path]);
    } catch (e) {
      print("Error eliminando archivo: $e");
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar datos, se necesita internet'));
          }

          final lugares = snapshot.data ?? [];

          if (lugares.isEmpty) {
            return const Center(child: Text('No hay registros'));
          }

          // 🔥 REEMPLAZA ÚNICAMENTE ESTE BLOQUE:
// return GridView.builder( ... );
//
// 👇 POR ESTE:

return ListView.builder(
  padding: const EdgeInsets.all(12),
  itemCount: lugares.length,
  itemBuilder: (context, index) {
    final l = lugares[index];

    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🖼️ IMAGEN PRINCIPAL
              SizedBox(
                width: double.infinity,
                height: 220,
                child: (l['imagen_principal'] != null &&
                        l['imagen_principal'].toString().isNotEmpty)
                    ? Image.network(
                        l['imagen_principal'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),

              /// 📄 INFORMACIÓN
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NOMBRE
                    Text(
                      l['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// DESCRIPCIÓN
                    if (l['descripcion'] != null)
                      Text(
                        l['descripcion'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),

                    const SizedBox(height: 10),

                    /// PRECIO
                    if (l['precio'] != null &&
    l['precio'].toString().trim().isNotEmpty)
  Text(
    l['precio'].toString(),
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.green,
    ),
  ),

                    const SizedBox(height: 14),

                    /// BOTÓN VER MÁS

Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LugaresDetallePorTipoPage(lugar: l),
        ),
      );
    },
    child: const Text(
      "Ver más",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color.fromARGB(255, 117, 223, 250),
      ),
    ),
  ),
),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
  top: 10,
  left: 10,
  child: FutureBuilder<bool>(
    future: FavoritosService.esFavorito(l['id'].toString()),
    builder: (context, snapshot) {
      final favorito = snapshot.data ?? false;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            favorito ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
          ),
          onPressed: () async {
            await FavoritosService.toggleFavorito(
              l['id'].toString(),
            );

            setState(() {});
          },
        ),
      );
    },
  ),
),

          /// 🔥 BOTONES ADMIN
          if (isAdmin)
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditarLugarPage(lugar: l),
                          ),
                        );

                        setState(() {
                          _future = _cargarLugares();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Eliminar lugar"),
                            content: const Text(
                              "¿Seguro que deseas eliminar este registro?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancelar"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _eliminarLugar(l);
                                },
                                child: const Text(
                                  "Eliminar",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.95),
    shape: BoxShape.circle,
  ),
  child: IconButton(
    icon: const Icon(
      Icons.format_list_numbered,
      color: Colors.orange,
    ),
    onPressed: () {
      _cambiarOrden(l);
    },
  ),
),
                ],
              ),
            ),
        ],
      ),
    );
  },
);
        },
      ),
    );
  }
}
