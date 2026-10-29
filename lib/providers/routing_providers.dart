import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/osrm_routing_repository.dart';
import '../data/repositories.dart';
import '../domain/models/route_path.dart';
import 'settings_provider.dart';

/// El servicio de rutas por calles, o null si la empresa no configuró uno (`routing_base_url`).
final routingRepositoryProvider = Provider<RoutingRepository?>((ref) {
  final url = ref.watch(settingsProvider).value?.routingBaseUrl;
  return url == null || url.isEmpty ? null : OsrmRoutingRepository(url);
});

/// La ruta por calles de esos puntos. null mientras carga, sin señal o si no hay servicio: en ese
/// caso el mapa dibuja la línea recta. Solo se vuelve a pedir cuando cambian los puntos.
final routePathProvider = FutureProvider.autoDispose.family<RoutePath?, RouteStops>((ref, stops) async {
  final repo = ref.watch(routingRepositoryProvider);
  if (repo == null) return null;
  try {
    return await repo.route(stops.points);
  } catch (_) {
    return null; // sin señal, tiempo agotado o respuesta rara: la línea recta sirve
  }
});
