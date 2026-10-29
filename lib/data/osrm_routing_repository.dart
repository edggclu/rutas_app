import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models/geo_point.dart';
import '../domain/models/route_path.dart';
import 'repositories.dart';

/// Pide la ruta por calles a un servidor OSRM (`/route/v1/driving/lng,lat;lng,lat`). La dirección
/// del servidor viene de los parámetros de la empresa (`routing_base_url`).
class OsrmRoutingRepository implements RoutingRepository {
  OsrmRoutingRepository(this._baseUrl, {http.Client? client}) : _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<RoutePath?> route(List<GeoPoint> stops) async {
    if (stops.length < 2) return null; // una sola parada no tiene trayecto
    final coords = stops.map((p) => '${p.lng},${p.lat}').join(';'); // OSRM pide longitud primero
    final base = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final uri = Uri.parse('$base/route/v1/driving/$coords?overview=full&geometries=geojson');
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    return parseOsrmRoute(json.decode(response.body) as Map<String, dynamic>);
  }
}

/// Lee la respuesta de OSRM. null si no trae una ruta (por ejemplo, un punto fuera de las calles).
RoutePath? parseOsrmRoute(Map<String, dynamic> body) {
  if (body['code'] != 'Ok') return null;
  final routes = body['routes'];
  if (routes is! List || routes.isEmpty || routes.first is! Map) return null;
  final route = routes.first as Map;
  final geometry = route['geometry'];
  final coordinates = geometry is Map ? geometry['coordinates'] : null;
  if (coordinates is! List) return null;
  final points = <GeoPoint>[
    for (final c in coordinates)
      if (c is List && c.length >= 2 && c[0] is num && c[1] is num) GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
  ];
  if (points.length < 2) return null;
  final legs = route['legs'];
  return RoutePath(
    points: points,
    legsKm: [
      if (legs is List)
        for (final l in legs)
          if (l is Map && l['distance'] is num) (l['distance'] as num) / 1000, // OSRM da metros
    ].map((d) => d.toDouble()).toList(),
  );
}
