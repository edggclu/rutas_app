import 'package:geolocator/geolocator.dart'; // la librería que habla con el GPS del teléfono

/// Un punto en el mapa: latitud y longitud.
class GeoPoint {

  final double lat; final double lng;
  const GeoPoint(this.lat, this.lng); // constructor: recibe latitud y longitud
}

/// Contrato: "algo que sabe dar la ubicación actual".
/// Existe para poder usar un falso en los tests porque no tienen gps
abstract class LocationService {
  Future<GeoPoint?> currentPosition(); // devuelve la posición, o null si no se pudo obtener
}

/// Version real - usa el gps del telefono
class DeviceLocationService implements LocationService {
  @override
  Future<GeoPoint?> currentPosition() async {
    try{
      final enabled = await Geolocator.isLocationServiceEnabled(); // revisa si el telefono tiene la ubicacion prendida
      if(!enabled) return null; // si esta apagada se sigue sin ubicacion
      var permission = await Geolocator.checkPermission(); // verifica los permisos de la app
      if (permission == LocationPermission.denied) { // todavía no se lo han pedido (o dijo "no" una vez)
        permission = await Geolocator.requestPermission(); // se lo pedimos ahora con la ventana de Android
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) { // lo nego o lo negó para siempre
        return null; // sin permiso se sigue sin ubicación
      }
      final p = await Geolocator.getCurrentPosition( // usando la funcion de la libreria
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // precisión alta (GPS, no solo antenas)
          timeLimit: Duration(seconds: 8), // si en 8 s no hay posición, lanza error
        ),
      );
      return GeoPoint(p.latitude, p.latitude); // convierte el resultado a la clase
    }
    catch (_) {
      return null; // marcar 'Llegué' nunca se bloquea por falta de GPS
    }
  }

}