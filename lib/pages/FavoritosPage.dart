import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'favoritos_service.dart';
import 'lugares_detalle_por_tipo_page.dart';
import '../widgets/bottom_nav.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _cargarFavoritos();
  }

  Future<List<dynamic>> _cargarFavoritos() async {
    final user = Supabase.instance.client.auth.currentUser;

    // Usuario invitado
    if (user == null) {
      final ids = await FavoritosService.obtenerFavoritosLocales();

      if (ids.isEmpty) return [];

      final lugares = await Supabase.instance.client
          .from('lugares')
          .select()
          .inFilter('id', ids);

      return lugares;
    }

    // Usuario con login
    final favoritos = await Supabase.instance.client
        .from('favoritos')
        .select('lugar_id')
        .eq('user_id', user.id);

    if (favoritos.isEmpty) return [];

    final ids = favoritos.map((f) => f['lugar_id']).toList();

    final lugares = await Supabase.instance.client
        .from('lugares')
        .select()
        .inFilter('id', ids);

    return lugares;
  }

  Future<void> _toggleFavorito(String lugarId) async {
    await FavoritosService.toggleFavorito(lugarId);

    setState(() {
      _future = _cargarFavoritos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNav(
  currentIndex: 1,
),
      appBar: AppBar(
        title: const Text("Mis Favoritos"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Error al cargar favoritos"),
            );
          }

          final lugares = snapshot.data ?? [];

          if (lugares.isEmpty) {
            return const Center(
              child: Text("No tienes favoritos"),
            );
          }

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
                        SizedBox(
                          width: double.infinity,
                          height: 220,
                          child: (l['imagen_principal'] != null)
                              ? Image.network(
                                  l['imagen_principal'],
                                  fit: BoxFit.cover,
                                )
                              : Container(color: Colors.grey[300]),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                l['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              if (l['descripcion'] != null)
                                Text(
                                  l['descripcion'],
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),

                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            LugaresDetallePorTipoPage(
                                          lugar: l,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Ver más"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _toggleFavorito(
                              l['id'].toString(),
                            );
                          },
                        ),
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