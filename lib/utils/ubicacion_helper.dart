import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class UbicacionHelper {
  static Future<bool> solicitarPermisoUbicacion(
    BuildContext context,
  ) async {
    /// 1. VALIDAR GPS
    bool servicioActivo =
        await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) {
      final activar = await _mostrarModalPermiso(
        context,
        icono: Icons.location_off_rounded,
        titulo: 'Activa tu ubicación',
        descripcion:
            'Para mostrar lugares cercanos, rutas y recomendaciones, necesitamos que actives la ubicación de tu dispositivo.',
        textoBoton: 'Activar',
        color: const Color(0xFF7CB342),
      );

      if (!activar) return false;

      await Geolocator.openLocationSettings();

      servicioActivo =
          await Geolocator.isLocationServiceEnabled();

      if (!servicioActivo) {
        return false;
      }
    }

    /// 2. REVISAR PERMISOS
    LocationPermission permiso =
        await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      final continuar = await _mostrarModalPermiso(
        context,
        icono: Icons.my_location_rounded,
        titulo: 'Permitir ubicación',
        descripcion:
            'Necesitamos acceso a tu ubicación para encontrar lugares cerca de ti y mostrar rutas de navegación.',
        textoBoton: 'Continuar',
        color: const Color(0xFF4CAF50),
      );

      if (!continuar) return false;

      permiso = await Geolocator.requestPermission();
    }

    /// 3. RECHAZADO
    if (permiso == LocationPermission.denied) {
      return false;
    }

    /// 4. BLOQUEADO
    if (permiso == LocationPermission.deniedForever) {
      final abrirConfig = await _mostrarModalPermiso(
        context,
        icono: Icons.settings_rounded,
        titulo: 'Permiso bloqueado',
        descripcion:
            'Bloqueaste el acceso a la ubicación. Actívalo desde configuración para continuar.',
        textoBoton: 'Configuración',
        color: const Color(0xFFE53935),
      );

      if (!abrirConfig) return false;

      await Geolocator.openAppSettings();

      return false;
    }

    return true;
  }

  static Future<bool> _mostrarModalPermiso(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String descripcion,
    required String textoBoton,
    required Color color,
  }) async {
    final resultado = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(
        milliseconds: 300,
      ),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 28,
              ),
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 12,
                      sigmaY: 12,
                    ),
                    child: Container(
                      padding:
                          const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF1F2A1F,
                        ).withOpacity(0.96),
                        borderRadius:
                            BorderRadius.circular(
                          32,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.35),
                            blurRadius: 30,
                            offset: const Offset(
                              0,
                              14,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Container(
                            width: 95,
                            height: 95,
                            decoration: BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color: color
                                  .withOpacity(
                                0.15,
                              ),
                              border: Border.all(
                                color: color
                                    .withOpacity(
                                  0.35,
                                ),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              icono,
                              size: 48,
                              color: color,
                            ),
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          Text(
                            titulo,
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          Text(
                            descripcion,
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(
                            height: 30,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      context,
                                      false,
                                    );
                                  },
                                  style:
                                      OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(
                                      color: Colors
                                          .white24,
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        22,
                                      ),
                                    ),
                                  ),
                                  child:
                                      const Text(
                                    'No, gracias',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .white,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 14,
                              ),

                              Expanded(
                                child:
                                    ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      context,
                                      true,
                                    );
                                  },
                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        color,
                                    foregroundColor:
                                        Colors
                                            .white,
                                    padding:
                                        const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        22,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    textoBoton,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder:
          (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.92,
              end: 1,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve:
                    Curves.easeOutBack,
              ),
            ),
            child: child,
          ),
        );
      },
    );

    return resultado ?? false;
  }
}