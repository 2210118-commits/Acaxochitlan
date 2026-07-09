import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final int notificacionesCount;
  final VoidCallback onMenu;
  final VoidCallback onNotifications;
  final VoidCallback onFavorites;

  const HomeHeader({
    super.key,
    required this.notificacionesCount,
    required this.onMenu,
    required this.onNotifications,
    required this.onFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff650B28),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [

                IconButton(
                  onPressed: onMenu,
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const Expanded(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [

      SizedBox(height: 4), // Ajusta este valor

      Text(
        "Donde la naturaleza, la cultura",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),

      SizedBox(height: 2),

      Text(
        "y la tradición se encuentran",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    ],
  ),
),

                Stack(
                  children: [

                    IconButton(
                      onPressed: onNotifications,
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),

                    if (notificacionesCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                  ],
                ),

                IconButton(
                  onPressed: onFavorites,
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}