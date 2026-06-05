import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../tienda_hidarte_page.dart';
import '../servicios_emergencia_page.dart';
import 'admin_experiencia_magica_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Administrador"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 15),
            child: Chip(
              label: Text(
                "ADMIN",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          )
        ],
      ),

      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.email ?? "Administrador"),
              accountEmail: const Text("Panel de control"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Inicio"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/inicio');
              },
            ),

            ListTile(
              leading: const Icon(Icons.cabin),
              title: const Text("Cabañas"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/cabanas');
              },
            ),

            ListTile(
              leading: const Icon(Icons.hotel),
              title: const Text("Hoteles"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/hoteles');
              },
            ),

            ListTile(
              leading: const Icon(Icons.place),
              title: const Text("Lugares Turísticos"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/lugares');
              },
            ),

            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text("Restaurantes"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/restaurantes');
              },
            ),

            ListTile(
              leading: const Icon(Icons.celebration),
              title: const Text("Festividades"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/festividades');
              },
            ),

            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text("Tienda hidarte"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TiendaHidartePage(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.emergency),
              title: const Text("Servicios de emergencia"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiciosEmergenciaPage(),
                  ),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Cerrar sesión",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/inicio',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 10),

            const Text(
              "Panel de Administración",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 5,
                children: [

                  _adminCard(
                    context,
                    icon: Icons.add_circle,
                    title: "Subir Actividad",
                    color: Colors.blue,
                    route: '/crear_publicacion',
                  ),

                  _adminCard(
                    context,
                    icon: Icons.list,
                    title: "Ver Actividades",
                    color: Colors.green,
                    route: '/publicaciones',
                  ),

                  _adminCard(
                    context,
                    icon: Icons.cloud_upload,
                    title: "Subir Hoteles / Cabañas etc.",
                    color: Colors.orange,
                    route: '/hoteles_cabanas',
                  ),

                  _adminCard(
                    context,
                    icon: Icons.image,
                    title: "Subir Carrusel",
                    color: Colors.purple,
                    route: '/subir-imagen',
                  ),
                  _adminCard(
  context,
  icon: Icons.emergency,
  title: "Servicios Emergencia",
  color: Colors.red,
  route: '/admin_servicios_emergencia',
),

_adminCard(
  context,
  icon: Icons.store,
  title: "Subir Tienda Hidarte",
  color: Colors.teal,
  route: '/admin_tienda_hidarte',
),
_adminCard(
  context,
  icon: Icons.wallpaper,
  title: "Fondo Inicio",
  color: Colors.indigo,
  route: '/cambiar_fondo_home',
),
_adminCard(
  context,
  icon: Icons.newspaper,
  title: "Subir Noticias",
  color: Colors.deepPurple,
  route: '/admin_noticias',
),

_adminCard(
  context,
  icon: Icons.auto_awesome,
  title: "Experiencia Mágica",
  color: Colors.amber,
  route: '/admin_experiencia_magica',
),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}