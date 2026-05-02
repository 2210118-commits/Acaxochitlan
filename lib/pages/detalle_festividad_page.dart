import 'package:flutter/material.dart';
import '../utils/image_viewer_helper.dart';
import 'package:acaxochi/widgets/video_player_widget.dart';
import '../widgets/texto_expandable.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';

class DetalleFestividadPage extends StatefulWidget {
  final Map<String, dynamic> festividad;

  const DetalleFestividadPage({
    super.key,
    required this.festividad,
  });

  @override
  State<DetalleFestividadPage> createState() => _DetalleFestividadPageState();
}

class _DetalleFestividadPageState extends State<DetalleFestividadPage> {
  String? diaSeleccionado;
  String formatearFecha(String fecha) {
  try {
    final date = DateTime.parse(fecha);
    return DateFormat("d/MMMM/yyyy", "es").format(date);
  } catch (e) {
    return fecha;
  }
}

Future<void> abrirMapa(double lat, double lng) async {
  final url = Uri.parse(
    "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'No se pudo abrir el mapa';
  }
}

DateTime parseHora(String hora) {
  try {
    // Intentar formato AM/PM
    return DateFormat.jm().parse(hora);
  } catch (e) {
    try {
      // Intentar formato 24 horas (ej: 20:30)
      return DateFormat("HH:mm").parse(hora);
    } catch (e) {
      return DateTime(2000, 1, 1, 0, 0);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final festividad = widget.festividad;
print(festividad['programa']);
    initializeDateFormatting('es');

    final double? lat = festividad['latitud'] != null
    ? double.tryParse(festividad['latitud'].toString())
    : null;

final double? lng = festividad['longitud'] != null
    ? double.tryParse(festividad['longitud'].toString())
    : null;

    final List<String> imagenes =
    (festividad['imagenes'] as List?)
        ?.where((e) => e != null && e.toString().isNotEmpty)
        .map((e) => e.toString())
        .toList()
    ?? [];

    final List<String> videos =
    (festividad['videos'] as List?)
        ?.where((e) => e != null && e.toString().isNotEmpty)
        .map((e) => e.toString())
        .toList() ?? [];

    final List<Map<String, dynamic>> programa =
    (festividad['programa'] is List)
        ? (festividad['programa'] as List)
            .where((e) => e != null)
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : [];

        Map<String, List<Map<String, dynamic>>> programaPorDia = {};

for (var item in programa) {
  final dia = (item["dia"] ?? "Sin día").toString();

  if (!programaPorDia.containsKey(dia)) {
    programaPorDia[dia] = [];
  }

  programaPorDia[dia]!.add(item);
}

List<String> diasOrdenados = programaPorDia.keys.toList();

/// ORDENAR ACTIVIDADES POR HORA (AM/PM)
for (var dia in programaPorDia.keys) {
  programaPorDia[dia]!.sort((a, b) {
    final horaA = parseHora((a["hora"] ?? "").toString());
    final horaB = parseHora((b["hora"] ?? "").toString());
    return horaA.compareTo(horaB);
  });
}
/// ORDENAR DIAS
diasOrdenados.sort((a, b) {
  final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  return numA.compareTo(numB);
});

diaSeleccionado ??= diasOrdenados.isNotEmpty ? diasOrdenados.first : null;

    final String fechaInicio = festividad['fecha_inicio']?.toString() ?? '';
final String fechaFin = festividad['fecha_fin']?.toString() ?? '';

    final List<String> soloImagenes = imagenes;
    final fechaInicioFormateada = formatearFecha(fechaInicio);
    final fechaFinFormateada = formatearFecha(fechaFin);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [

              /// IMAGEN SUPERIOR
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: const Color.fromARGB(255, 167, 166, 166),
                flexibleSpace: FlexibleSpaceBar(
                  background: imagenes.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            ImageViewerHelper.abrir(
                              context,
                              images: soloImagenes,
                              initialIndex: 0,
                            );
                          },
                          child: Image.network(
                            imagenes.first,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(color: const Color.fromARGB(255, 168, 168, 168)),
                ),
              ),

              /// TITULO + DESCRIPCION
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        festividad['titulo']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (fechaInicio.isNotEmpty || fechaFin.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        const Icon(Icons.calendar_month, color: Colors.deepPurple),
        const SizedBox(width: 6),
        Text(
          "Del $fechaInicioFormateada al $fechaFinFormateada",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  ),

                      const SizedBox(height: 10),

                      TextoExpandable(
                        texto: festividad['descripcion']?.toString() ?? '',
                        maxLineas: 4,
                        fontSize: 16,
                      ),

                      if (lat != null && lng != null) ...[
  const SizedBox(height: 15),

  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () => abrirMapa(lat, lng),
      icon: const Icon(Icons.directions),
      label: const Text("Cómo llegar"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: const Color.fromARGB(255, 210, 209, 212),
      ),
    ),
  ),
],
                      if (programa.isNotEmpty) ...[

  const SizedBox(height: 20),

  Row(
    children: const [
      Icon(Icons.event_note, color: Colors.deepPurple),
      SizedBox(width: 8),
      Text(
        "Eventos",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),

  const SizedBox(height: 15),

  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    /// TABS DE DIAS (SIN DefaultTabController)
    SizedBox(
  height: 40,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: diasOrdenados.map((dia) {
      final seleccionado = dia == diaSeleccionado;

      return GestureDetector(
        onTap: () {
          setState(() {
            diaSeleccionado = dia;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: seleccionado
                ? Colors.deepPurple
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            dia,
            style: TextStyle(
              color: seleccionado ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }).toList(),
  ),
),

    const SizedBox(height: 10),

    Text(
  diaSeleccionado ?? '',
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.deepPurple,
  ),
),
const SizedBox(height: 8),

    /// CONTENIDO (sin TabBarView)
    SizedBox(
      height: 300,
      child: Builder(
  builder: (_) {
    if (diaSeleccionado == null) {
      return const Center(child: Text("Sin actividades"));
    }

    final actividades = programaPorDia[diaSeleccionado!] ?? [];

    if (actividades.isEmpty) {
      return const Center(child: Text("Sin actividades"));
    }

    return ListView.builder(
      itemCount: actividades.length,
      itemBuilder: (context, index) {
        final item = actividades[index];
        final hora = (item["hora"] ?? "").toString();
        final actividad = (item["actividad"] ?? "").toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  hora,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(actividad)),
            ],
          ),
        );
      },
    );
  },
),
    ),
  ],
),
],
                    ],
                  ),
                ),
              ),

              /// TABS
              const SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    labelColor: Color.fromARGB(255, 63, 62, 62),
                    indicatorColor: Colors.deepPurple,
                    tabs: [
                      Tab(text: "Galería"),
                      Tab(text: "Videos"),
                    ],
                  ),
                ),
              ),
            ];
          },

          /// CONTENIDO
          body: TabBarView(
            children: [

              /// GALERIA
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  itemCount: imagenes.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {

                    final url = imagenes[index];

                    return GestureDetector(
                      onTap: () {
                        ImageViewerHelper.abrir(
                          context,
                          images: soloImagenes,
                          initialIndex: index,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// VIDEOS
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  itemCount: videos.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {

                    return VideoPlayerWidget(
                      videoUrl: videos[index],
                      aspectRatio: 1,
                      borderRadius: 12,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// DELEGATE PARA TABBAR
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}