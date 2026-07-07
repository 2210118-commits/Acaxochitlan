import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../pages/lugares_page.dart';
import '../../pages/cabanas_page.dart';
import '../../pages/hoteles_page.dart';
import '../../pages/restaurantes_page.dart';
import '../../pages/actividades_page.dart';
import '../../pages/festividades_page.dart';
import '../../pages/experiencia_magica_page.dart';
import '../../pages/tienda_hidarte_page.dart';
import '../../pages/servicios_emergencia_page.dart';

class HomeDrawer extends StatelessWidget {
  final bool esAdmin;

  const HomeDrawer({
    super.key,
    required this.esAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        "assets/images/menbrete1ho.png",
                      ),
                      fit: BoxFit.cover,
                      repeat: ImageRepeat.repeatX,
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(.60),
                        Colors.black.withOpacity(.30),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white30,
                          ),
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 15),

                       Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Acaxochitlán\n",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: "\"Pueblo mágico\"",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Inicio"),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.place),
            title: const Text("Atractivos Turísticos"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LugaresPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.house_siding),
            title: const Text("Cabañas"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CabanasPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.directions_walk),
            title: const Text("Actividades"),
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActividadesPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.celebration),
            title: const Text("Festividades"),
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FestividadesPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.hotel),
            title: const Text("Hoteles"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HotelesPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text("Restaurantes"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RestaurantesPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text("Experiencia Mágica"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExperienciaMagicaPage(),
                ),
              );
            },
          ),
                    ListTile(
            leading: const Icon(Icons.palette),
            title: const Text("Tienda Hidarte"),
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

          if (!esAdmin)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text("Iniciar Sesión"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),

          if (esAdmin) ...[
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Panel Administrador"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin');
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                "Cerrar sesión",
                style: TextStyle(
                  color: Colors.red,
                ),
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
        ],
      ),
    );
  }
}