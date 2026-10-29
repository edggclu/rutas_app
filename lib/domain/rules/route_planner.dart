import 'dart:math' as math;

import '../models/enums.dart';
import '../models/geo_point.dart';
import '../models/models.dart';
import '../models/route_path.dart';

/// Distancia en línea recta entre dos puntos, en km (fórmula de haversine). Es una aproximación
/// de la distancia por carretera, suficiente para comparar qué visita queda más cerca.
double distanceKm(GeoPoint a, GeoPoint b) {
  const earthKm = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * earthKm * math.asin(math.sqrt(h));
}

/// La ubicación de la visita, o null si el servidor no la mandó.
GeoPoint? pointOf(Visit v) {
  final lat = v.place.lat;
  final lng = v.place.lng;
  return lat == null || lng == null ? null : GeoPoint(lat, lng);
}

/// La ruta del día que ve el técnico. El orden ya no lo manda el servidor: lo calcula la app con
/// el vecino más cercano y el técnico puede elegir con qué visita empezar.
class RoutePlan {
  const RoutePlan({
    required this.active,
    required this.ordered,
    required this.done,
    required this.start,
    required this.legsKm,
    required this.suggestedFirstId,
  });

  final List<Visit> active; // la que va En camino o En sitio (ya no se reordena)
  final List<Visit> ordered; // las que faltan, en el orden de la ruta
  final List<Visit> done; // las cerradas: ya no cuentan para la ruta
  final GeoPoint? start; // de dónde sale la ruta (donde está el técnico o la oficina)
  final List<double?> legsKm; // km desde el punto anterior a cada visita de [ordered]
  final int? suggestedFirstId; // con cuál empezaría el algoritmo, sin importar lo que se eligió

  /// Todas las visitas en el orden en que se muestran: la activa, las que faltan y las cerradas.
  List<Visit> get all => [...active, ...ordered, ...done];

  /// ¿La primera visita es distinta de la que sugiere el algoritmo (el técnico la eligió)?
  bool get isCustom => ordered.isNotEmpty && ordered.first.id != suggestedFirstId;

  /// Las visitas que se pueden mirar en el mapa: la que va En camino o En sitio y las que faltan.
  /// Sin la activa, la última visita en camino dejaría el mapa diciendo que ya no queda ninguna.
  List<Visit> get stops => [...active, ...ordered];

  /// Los puntos por los que pasa la ruta: de donde sale (si se sabe) y cada visita por hacer que
  /// tiene ubicación, en orden.
  List<GeoPoint> get stopPoints => [
        if (start != null) start!,
        for (final v in ordered)
          if (pointOf(v) != null) pointOf(v)!,
      ];

  /// Los km desde el punto anterior hasta la visita [i] de [ordered]. Si ya se tiene la ruta por
  /// calles, esos km; si no, la distancia en línea recta.
  double? legKm(int i, RoutePath? path) {
    final legs = path?.legsKm;
    if (legs != null) {
      final leg = start == null ? i - 1 : i; // sin punto de salida, la primera visita no tiene tramo
      if (leg >= 0 && leg < legs.length) return legs[leg];
    }
    return legsKm[i];
  }
}

/// Ordena [pending] con el vecino más cercano. Empieza por [firstId] si se eligió una; si no,
/// por la más cercana a [start]; si tampoco hay punto de salida, por la primera de la lista.
/// Las visitas sin ubicación van al final, en el orden en que llegaron.
List<Visit> nearestNeighborOrder(List<Visit> pending, {GeoPoint? start, int? firstId}) {
  final located = [for (final v in pending) if (pointOf(v) != null) v];
  final unlocated = [for (final v in pending) if (pointOf(v) == null) v];
  final out = <Visit>[];

  Visit nearestTo(GeoPoint from, List<Visit> among) =>
      among.reduce((a, b) => distanceKm(from, pointOf(a)!) <= distanceKm(from, pointOf(b)!) ? a : b);

  Visit? current;
  if (firstId != null) current = located.where((v) => v.id == firstId).firstOrNull;
  current ??= located.isEmpty ? null : (start == null ? located.first : nearestTo(start, located));

  while (current != null) {
    out.add(current);
    located.remove(current);
    current = located.isEmpty ? null : nearestTo(pointOf(current)!, located);
  }
  return [...out, ...unlocated];
}

/// Arma la ruta a partir de las visitas ya con su estado (`applyEvents`). Las cerradas no entran
/// en el cálculo; el punto de salida es la visita activa, la última que se cerró o la oficina.
RoutePlan planRoute(List<Visit> visits, {GeoPoint? office, int? firstId}) {
  final active = [for (final v in visits) if (v.status == VisitStatus.enRoute || v.status == VisitStatus.onSite) v];
  final done = [for (final v in visits) if (v.status == VisitStatus.done) v];
  final pending = [for (final v in visits) if (v.status == VisitStatus.pending) v];

  GeoPoint? start;
  if (active.isNotEmpty) {
    start = pointOf(active.first);
  } else if (done.isNotEmpty) {
    start = pointOf(done.reduce((a, b) => (b.arrivedAt ?? DateTime(0)).isAfter(a.arrivedAt ?? DateTime(0)) ? b : a));
  }
  start ??= office;

  final ordered = nearestNeighborOrder(pending, start: start, firstId: firstId);
  final suggested = nearestNeighborOrder(pending, start: start);

  final legs = <double?>[];
  GeoPoint? from = start;
  for (final v in ordered) {
    final p = pointOf(v);
    legs.add(from == null || p == null ? null : distanceKm(from, p));
    from = p ?? from;
  }

  return RoutePlan(
    active: active,
    ordered: ordered,
    done: done,
    start: start,
    legsKm: legs,
    suggestedFirstId: suggested.isEmpty ? null : suggested.first.id,
  );
}
