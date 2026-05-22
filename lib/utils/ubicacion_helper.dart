import 'package:geolocator/geolocator.dart';

class UbicacionHelper {
  static Future<bool> solicitarPermisoUbicacion() async {
    // Revisar permiso
    LocationPermission permiso =
        await Geolocator.checkPermission();

    // Pedir permiso nativo
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    // Rechazado
    if (permiso == LocationPermission.denied) {
      return false;
    }

    // Bloqueado permanentemente
    if (permiso == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    // Revisar GPS
    bool gpsActivo =
        await Geolocator.isLocationServiceEnabled();

    if (!gpsActivo) {
      await Geolocator.openLocationSettings();

      // volver a revisar al regresar
      gpsActivo =
          await Geolocator.isLocationServiceEnabled();

      if (!gpsActivo) {
        return false;
      }
    }

    return true;
  }
}