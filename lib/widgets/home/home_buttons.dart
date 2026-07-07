import 'package:flutter/material.dart';

class HomeButtons extends StatelessWidget {
  final VoidCallback onFestividades;
  final VoidCallback onCercaDeMi;

  const HomeButtons({
    super.key,
    required this.onFestividades,
    required this.onCercaDeMi,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: _BotonPrincipal(
              color: const Color(0xffD8A72C),
              icon: Icons.celebration,
              texto: "Festividades",
              onTap: onFestividades,
              textoColor: Colors.white,
              iconColor: Colors.white,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: _BotonPrincipal(
              color: Colors.white,
              borderColor: const Color(0xff2F6F5E),
              icon: Icons.my_location,
              texto: "Cerca de mí",
              onTap: onCercaDeMi,
              textoColor: const Color(0xff2F6F5E),
              iconColor: const Color(0xff2F6F5E),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonPrincipal extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final Color textoColor;
  final Color iconColor;
  final String texto;
  final IconData icon;
  final VoidCallback onTap;

  const _BotonPrincipal({
    required this.color,
    required this.icon,
    required this.texto,
    required this.onTap,
    required this.textoColor,
    required this.iconColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 2)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 15,
              ),

              const SizedBox(width: 10),

              Flexible(
                child: Text(
                  texto,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textoColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}