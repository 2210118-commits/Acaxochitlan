import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detalle_tienda_hidarte_page.dart';

class TiendaHidartePage extends StatefulWidget {
  const TiendaHidartePage({super.key});

  @override
  State<TiendaHidartePage> createState() => _TiendaHidartePageState();
}

class _TiendaHidartePageState extends State<TiendaHidartePage> {

  @override
  void initState() {
    super.initState();
    _cargarYAbrir();
  }

  // 🔥 CARGA Y ABRE AUTOMÁTICAMENTE
  Future<void> _cargarYAbrir() async {
    try {
      final productos = await Supabase.instance.client
          .from('tienda_hidarte')
          .select()
          .order('created_at', ascending: false);

      if (productos.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleTiendaHidartePage(
                producto: productos.first, // 👈 abre el primero
              ),
            ),
          );
        });
      } else {
        _mostrarError("No hay productos");
      }
    } catch (e) {
      _mostrarError("Error cargando productos");
    }
  }

  void _mostrarError(String mensaje) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    });
  }

  // 🔥 SOLO LOADING (NO LISTA)
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}