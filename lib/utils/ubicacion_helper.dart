import 'package:geolocator/geolocator.dart';

class UbicacionHelper {
  static Future<bool> solicitarPermisoUbicacion() async {
    // Verificar si el GPS está activado
    bool gpsActivo = await Geolocator.isLocationServiceEnabled();

    if (!gpsActivo) {
      await Geolocator.openLocationSettings();

      gpsActivo = await Geolocator.isLocationServiceEnabled();

      if (!gpsActivo) {
        return false;
      }
    }

    // Revisar permiso actual
    LocationPermission permiso =
        await Geolocator.checkPermission();

    // Solicitar permiso si aún no está concedido
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    // Usuario rechazó el permiso
    if (permiso == LocationPermission.denied) {
      return false;
    }

    // Usuario rechazó permanentemente
    if (permiso == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }
}