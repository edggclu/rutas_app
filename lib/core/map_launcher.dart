import 'package:url_launcher/url_launcher.dart'; // abre otras apps

/// Abre el mapa (Maps, Waze...) en un lugar. Prefiere las coordenadas; si faltan, usa la dirección.
/// Devuelve true si se pudo abrir.
Future<bool> openMap({ // abre el mapa
  double? lat, // latitud (puede faltar)
  double? lng, // longitud (puede faltar)
  required String label, // nombre del lugar
  required String address, // dirección
}) async {
  final hasPoint = lat != null && lng != null; // ¿hay coordenadas?
  final uris = <Uri>[ // los enlaces a probar, en orden
    if (hasPoint) Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label)})'), // "geo:" abre el selector de Android (Maps, Waze...)
    Uri.parse( // enlace web de Google Maps, como respaldo
      'https://www.google.com/maps/search/?api=1&query='
      '${hasPoint ? '$lat,$lng' : Uri.encodeComponent(address)}', // coordenadas si hay; si no, la dirección
    ),
  ];
  for (final u in uris) { // prueba cada enlace
    try { // si uno falla, prueba el siguiente
      if (await launchUrl(u, mode: LaunchMode.externalApplication)) return true; // se abrió
    } catch (_) {} // se ignora y sigue con el siguiente
  }
  return false; // ninguno funcionó
}