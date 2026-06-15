import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/FavoritosPage.dart';
import '../pages/servicios_emergencia_page.dart';
import '../pages/tienda_hidarte_page.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onHomePressed;

  const BottomNav({
    super.key,
    required this.currentIndex,
    this.onHomePressed,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,

      // 🎨 Apariencia
      backgroundColor: const Color.fromARGB(223, 59, 1, 14),
      elevation: 15,
      selectedItemColor: const Color(0xFF1565C0),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      iconSize: 20,

      showSelectedLabels: true,
      showUnselectedLabels: true,

      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.1,
      ),

      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
      ),

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          activeIcon: Icon(Icons.home_rounded),
          label: "Inicio",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border_rounded),
          activeIcon: Icon(Icons.favorite_rounded),
          label: "Favoritos",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.palette_outlined),
          activeIcon: Icon(Icons.palette_rounded),
          label: "Tienda\nHidarte",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emergency_outlined),
          activeIcon: Icon(Icons.emergency),
          label: "Emergencias",
        ),
      ],

      onTap: (index) {
        switch (index) {
          case 0:
            if (onHomePressed != null) {
              onHomePressed!();
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomePage(),
                ),
                (route) => false,
              );
            }
            break;

          case 1:
  if (currentIndex != 1) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FavoritosPage(),
      ),
    );
  }
  break;

case 2:
  if (currentIndex != 2) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TiendaHidartePage(),
      ),
    );
  }
  break;

case 3:
  if (currentIndex != 3) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ServiciosEmergenciaPage(),
      ),
    );
  }
  break;
        }
      },
    );
  }
}