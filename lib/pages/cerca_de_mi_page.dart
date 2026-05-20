import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'lugares_detalle_por_tipo_page.dart';

class CercaDeMiPage extends StatefulWidget {
  const CercaDeMiPage({super.key});

  @override
  State<CercaDeMiPage> createState() => _CercaDeMiPageState();
}

class _CercaDeMiPageState extends State<CercaDeMiPage> {
  bool cargando = true;
  List<Map<String, dynamic>> lugares = [];
  List<Map<String, dynamic>> lugaresFiltrados = [];

  String filtroActual = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarLugaresCercanos();
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('No se pudo abrir $url');
    }
  }

  Future<void> _cargarLugaresCercanos() async {
    setState(() {
      cargando = true;
    });

    try {
      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final response =
          await Supabase.instance.client.from('lugares').select();

      List<Map<String, dynamic>> lugaresConDistancia = [];

      for (var lugar in response) {
        if (lugar['latitud'] == null || lugar['longitud'] == null) continue;

        final distancia = Geolocator.distanceBetween(
          posicion.latitude,
          posicion.longitude,
          double.parse(lugar['latitud'].toString()),
          double.parse(lugar['longitud'].toString()),
        );

        lugar['distancia'] = distancia;
        lugaresConDistancia.add(Map<String, dynamic>.from(lugar));
      }

      lugaresConDistancia.sort(
        (a, b) => a['distancia'].compareTo(b['distancia']),
      );

      if (!mounted) return;

      setState(() {
        lugares = lugaresConDistancia;
        _aplicarFiltro();
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error obteniendo ubicación: $e'),
        ),
      );
    }
  }

  void _aplicarFiltro() {
    if (filtroActual == 'todos') {
      lugaresFiltrados = List.from(lugares);
    } else {
      lugaresFiltrados = lugares
          .where((l) => l['tipo'] == filtroActual)
          .toList();
    }
  }

  String _formatearDistancia(double metros) {
    if (metros < 1000) {
      return '${metros.toStringAsFixed(0)} m';
    }
    return '${(metros / 1000).toStringAsFixed(1)} km';
  }

  String _tipoBonito(String tipo) {
    switch (tipo) {
      case 'hotel':
        return 'Hotel';
      case 'cabana':
        return 'Cabaña';
      case 'restaurante':
        return 'Restaurante';
      case 'lugar_turistico':
        return 'Atractivo';
      default:
        return tipo;
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'hotel':
        return Icons.hotel;
      case 'cabana':
        return Icons.cabin;
      case 'restaurante':
        return Icons.restaurant;
      default:
        return Icons.place;
    }
  }

  Widget _chipFiltro(String label, String valor) {
    final seleccionado = filtroActual == valor;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: seleccionado,
        selectedColor: Colors.blueAccent,
        labelStyle: TextStyle(
          color: seleccionado ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) {
          setState(() {
            filtroActual = valor;
            _aplicarFiltro();
          });
        },
      ),
    );
  }

  Widget _cardLugar(Map<String, dynamic> l) {
  final lat = l['latitud'];
  final lng = l['longitud'];

  return Container(
    margin: const EdgeInsets.only(bottom: 22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.14),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          SizedBox(
            height: 280,
            width: double.infinity,
            child: Image.network(
              l['imagen_principal'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),

          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.82),
                ],
              ),
            ),
          ),

          /// TIPO
          Positioned(
  top: 16,
  left: 16,
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.56),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: Colors.white.withOpacity(0.55),
      ),
    ),
    child: Row(
      children: [
        Icon(
          _iconoTipo(l['tipo']),
          size: 16,
          color: const Color.fromARGB(255, 99, 98, 98),
        ),
        const SizedBox(width: 6),
        Text(
          _tipoBonito(l['tipo']),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 12, 12, 12),
          ),
        ),
      ],
    ),
  ),
),

          /// DISTANCIA
          Positioned(
  top: 16,
  right: 16,
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.56),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: Colors.white.withOpacity(0.55),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.near_me,
          color: Color.fromARGB(255, 22, 138, 233),
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          _formatearDistancia(l['distancia']),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 8, 8, 8),
          ),
        ),
      ],
    ),
  ),
),
          /// NOMBRE + BOTONES
Positioned(
  bottom: 18,
  left: 18,
  right: 18,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l['nombre'] ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 12),

      Row(
        children: [
          InkWell(
  onTap: () {
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
  borderRadius: BorderRadius.circular(20),
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F6FA),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.visibility,
          size: 15,
          color: Color(0xFF1F2937),
        ),
        SizedBox(width: 6),
        Text(
          "Detalle",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  ),
),

          const SizedBox(width: 8),

          InkWell(
  onTap: () {
    _abrirUrl(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
    );
  },
  borderRadius: BorderRadius.circular(20),
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF34A853),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.directions,
          size: 15,
          color: Colors.white,
        ),
        SizedBox(width: 6),
        Text(
          "Llegar",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
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
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text(
          "📍 Cerca de ti",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarLugaresCercanos,
        child: cargando
            ? ListView(
                children: const [
                  SizedBox(height: 250),
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Buscando lugares cercanos...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              )
            : lugaresFiltrados.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 220),
                      Icon(
                        Icons.location_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'No encontramos lugares cercanos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2196F3),
                              Color(0xFF1565C0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Explora cerca de ti',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${lugaresFiltrados.length} lugares encontrados',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        height: 45,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _chipFiltro('Todos', 'todos'),
                            _chipFiltro('Hoteles', 'hotel'),
                            _chipFiltro('Restaurantes', 'restaurante'),
                            _chipFiltro('Cabañas', 'cabana'),
                            _chipFiltro('Atractivos', 'lugar_turistico'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      ...lugaresFiltrados.map(_cardLugar),
                    ],
                  ),
      ),
    );
  }
}