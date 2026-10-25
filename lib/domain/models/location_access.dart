/// Si la app puede leer la ubicación del teléfono.
enum LocationAccess {
  granted, // permiso dado y GPS prendido
  denied, // todavía no lo ha dado: se puede volver a pedir
  deniedForever, // lo negó para siempre: solo se cambia en los ajustes de Android
  serviceOff; // el GPS del teléfono está apagado

  bool get isGranted => this == LocationAccess.granted;
}
