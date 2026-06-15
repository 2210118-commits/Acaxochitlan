import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/bottom_nav.dart';

class ServiciosEmergenciaPage extends StatefulWidget {
  const ServiciosEmergenciaPage({super.key});

  @override
  State<ServiciosEmergenciaPage> createState() => _ServiciosEmergenciaPageState();
}

class _ServiciosEmergenciaPageState extends State<ServiciosEmergenciaPage> {

  final supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> serviciosFuture;

  @override
  void initState() {
    super.initState();
    serviciosFuture = obtenerServicios();
  }

  Future<List<Map<String, dynamic>>> obtenerServicios() async {

    final response = await supabase
        .from('servicios_emergencia')
        .select()
        .eq('activo', true)
        .order('nombre');

    return List<Map<String, dynamic>>.from(response);
  }

  /// 📞 Llamar teléfono
  Future<void> llamar(String telefono) async {

  if (telefono.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Número no disponible"),
      ),
    );
    return;
  }

  final Uri url = Uri(scheme: 'tel', path: telefono);

  try {
    final bool launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication, // 👈 IMPORTANTE
    );

    if (!launched) {
      throw 'No se pudo abrir el marcador';
    }

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No se pudo realizar la llamada"),
      ),
    );
  }
}

  IconData obtenerIcono(String icono) {
    switch (icono) {
      case "police":
        return Icons.local_police;
      case "hospital":
        return Icons.local_hospital;
      case "fire":
        return Icons.fire_truck;
      case "civil":
        return Icons.support_agent;
      default:
        return Icons.phone;
    }
  }

  Color obtenerColor(String color) {
    switch (color) {
      case "blue":
        return Colors.blue;
      case "red":
        return Colors.red;
      case "orange":
        return Colors.orange;
      case "green":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 🔄 refrescar lista
  Future<void> refrescar() async {
    setState(() {
      serviciosFuture = obtenerServicios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      bottomNavigationBar: const BottomNav(
  currentIndex: 3,
),

      appBar: AppBar(
        title: const Text("Servicios de emergencia"),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: serviciosFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No hay servicios disponibles"),
            );
          }

          final servicios = snapshot.data!;

          return RefreshIndicator(
            onRefresh: refrescar,

            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: servicios.length,
              separatorBuilder: (_, __) => const Divider(),

              itemBuilder: (context, index) {

                final servicio = servicios[index];
                final telefono = servicio["telefono"] ?? "";

                return Container(
  margin: const EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(15),
    gradient: LinearGradient(
      colors: [
        Colors.white,
        obtenerColor(servicio["color"]).withOpacity(0.05),
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  ),
  child: ListTile(
    contentPadding: const EdgeInsets.all(16),

    leading: CircleAvatar(
      radius: 28,
      backgroundColor:
          obtenerColor(servicio["color"]).withOpacity(.15),
      child: Icon(
        obtenerIcono(servicio["icono"]),
        color: obtenerColor(servicio["color"]),
        size: 28,
      ),
    ),

    title: Text(
      servicio["nombre"] ?? "",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),

    subtitle: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                telefono,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          if (servicio["descripcion"] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                servicio["descripcion"],
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
        ],
      ),
    ),

    trailing: Container(
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.call, color: Colors.green),
        onPressed: () {
          if (telefono.isNotEmpty) {
            llamar(telefono);
          }
        },
      ),
    ),

    onTap: () {
      if (telefono.isNotEmpty) {
        llamar(telefono);
      }
    },
  ),
);
              },
            ),
          );
        },
      ),

      /// 🚨 botón SOS
      floatingActionButton: FloatingActionButton.extended(
  backgroundColor: Colors.red.shade700,
  icon: const Icon(Icons.warning_rounded),
  label: const Text(
    "Emergencia 911",
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  onPressed: () {
    llamar("911");
  },
),
    );
  }
}