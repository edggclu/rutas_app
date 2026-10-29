import 'geo_point.dart';

/// Los puntos por los que pasa la ruta, en orden. Tiene igualdad por valor para que un provider no
/// vuelva a pedir el trayecto cuando cambia otra cosa pero los puntos son los mismos.
class RouteStops {
  const RouteStops(this.points);

  final List<GeoPoint> points;

  @override
  bool operator ==(Object other) =>
      other is RouteStops && other.points.length == points.length && _same(other.points);

  bool _same(List<GeoPoint> o) {
    for (var i = 0; i < points.length; i++) {
      if (points[i] != o[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(points);
}

/// La ruta por calles entre los puntos: la línea que sigue las calles y cuántos km tiene cada tramo.
class RoutePath {
  const RoutePath({required this.points, required this.legsKm});

  final List<GeoPoint> points; // la línea para dibujar
  final List<double> legsKm; // km por calles de cada tramo, de un punto al siguiente
}
