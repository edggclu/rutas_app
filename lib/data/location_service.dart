import 'package:geolocator/geolocator.dart';

import '../domain/models/geo_point.dart';
import '../domain/models/location_access.dart';

export '../domain/models/geo_point.dart'; // quien importe el servicio de ubicación sigue viendo GeoPoint

/// Contrato: "algo que sabe dar la ubicación actual".
/// Existe para poder usar un falso en los tests porque no tienen gps
abstract class LocationService {
  Future<GeoPoint?> currentPosition(); // devuelve la posición, o null si no se pudo obtener
  Future<LocationAccess> access(); // revisa el estado del permiso y del GPS, sin pedir nada
  Future<LocationAccess> request(); // pide el permiso con la ventana de Android
  Future<void> openSettings(); // abre los ajustes de la app (o del GPS) para cambiarlo a mano
}

/// Version real - usa el gps del telefono
class DeviceLocationService implements LocationService {
  LocationAccess _fromPermission(LocationPermission p) => switch (p) { // traduce el permiso de la librería
        LocationPermission.denied || LocationPermission.unableToDetermine => LocationAccess.denied,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        LocationPermission.whileInUse || LocationPermission.always => LocationAccess.granted,
      };

  @override
  Future<LocationAccess> access() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff; // GPS apagado
    return _fromPermission(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) { // todavía no se lo han pedido (o dijo "no" una vez)
      permission = await Geolocator.requestPermission(); // se lo pedimos ahora con la ventana de Android
    }
    return _fromPermission(permission);
  }

  @override
  Future<void> openSettings() async {
    final current = await access();
    if (current == LocationAccess.serviceOff) {
      await Geolocator.openLocationSettings(); // ajustes del GPS
    } else {
      await Geolocator.openAppSettings(); // ajustes de la app
    }
  }

  @override
  Future<GeoPoint?> currentPosition() async {
    try{
      if (!(await request()).isGranted) return null; // sin permiso o con el GPS apagado se sigue sin ubicación
      final p = await Geolocator.getCurrentPosition( // usando la funcion de la libreria
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // precisión alta (GPS, no solo antenas)
          timeLimit: Duration(seconds: 8), // si en 8 s no hay posición, lanza error
        ),
      );
      return GeoPoint(p.latitude, p.longitude); // convierte el resultado a la clase
    }
    catch (_) {
      return null; // marcar 'Llegué' nunca se bloquea por falta de GPS
    }
  }

}
