import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/models/geo_point.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/rules/route_planner.dart';

/// Una visita de prueba en una línea norte-sur: la latitud crece con [km] (≈ 1 km por cada 0.009°).
Visit _visit(int id, {double? km, String status = 'pending', String? arrivedAt}) => Visit.fromJson({
      'id': id,
      'order': id,
      'status': status,
      if (arrivedAt != null) 'arrived_at': arrivedAt,
      'client': {'id': id, 'name': 'Cliente $id', 'overdue': false},
      'place': {'id': id, 'name': 'Lugar $id', 'address': '', 'lat': km == null ? null : 20.0 + km * 0.009, 'lng': km == null ? null : -105.0},
      'job': {'id': id, 'folio': 'TEL-$id'},
    });

GeoPoint _at(double km) => GeoPoint(20.0 + km * 0.009, -105.0);
List<int> _ids(Iterable<Visit> vs) => [for (final v in vs) v.id];

void main() {
  test('la distancia entre dos puntos', () {
    expect(distanceKm(const GeoPoint(0, 0), const GeoPoint(0, 0)), 0);
    expect(distanceKm(const GeoPoint(0, 0), const GeoPoint(0, 1)), closeTo(111.19, 0.1)); // un grado en el ecuador
  });

  group('vecino más cercano', () {
    final visits = [_visit(1, km: 5), _visit(2, km: 1), _visit(3, km: 3)];

    test('empieza por la más cercana al punto de salida y sigue de cercana en cercana', () {
      expect(_ids(nearestNeighborOrder(visits, start: _at(0))), [2, 3, 1]);
    });

    test('si el técnico elige con cuál empezar, la ruta se rehace desde esa', () {
      expect(_ids(nearestNeighborOrder(visits, start: _at(0), firstId: 1)), [1, 3, 2]);
    });

    test('sin punto de salida empieza por la primera de la lista', () {
      expect(_ids(nearestNeighborOrder(visits)), [1, 3, 2]);
    });

    test('una elegida que ya no está se ignora', () {
      expect(_ids(nearestNeighborOrder(visits, start: _at(0), firstId: 99)), [2, 3, 1]);
    });

    test('las visitas sin ubicación van al final', () {
      final v = [_visit(1, km: null), _visit(2, km: 4), _visit(3, km: 1)];
      expect(_ids(nearestNeighborOrder(v, start: _at(0))), [3, 2, 1]);
    });

    test('sin visitas, nada', () => expect(nearestNeighborOrder([]), isEmpty));
  });

  group('la ruta del día', () {
    test('las cerradas ya no cuentan y la ruta sale de la última que se cerró', () {
      final plan = planRoute([
        _visit(1, km: 0, status: 'done', arrivedAt: '2026-10-06T14:00:00Z'),
        _visit(2, km: 10, status: 'done', arrivedAt: '2026-10-06T16:00:00Z'), // la más reciente
        _visit(3, km: 12),
        _visit(4, km: 1),
      ], office: _at(0));
      expect(_ids(plan.ordered), [3, 4]); // desde el km 10, la del km 12 queda más cerca que la del km 1
      expect(_ids(plan.done), [1, 2]);
      expect(plan.start!.lat, closeTo(_at(10).lat, 1e-9));
    });

    test('la visita activa no se reordena y la ruta sale de ella', () {
      final plan = planRoute([_visit(1, km: 8, status: 'on_site'), _visit(2, km: 0), _visit(3, km: 9)], office: _at(0));
      expect(_ids(plan.active), [1]);
      expect(_ids(plan.ordered), [3, 2]);
      expect(_ids(plan.all), [1, 3, 2]); // activa, las que faltan y al final las cerradas
    });

    test('sin cerradas ni activas sale de la oficina', () {
      final plan = planRoute([_visit(1, km: 9), _visit(2, km: 2)], office: _at(0));
      expect(_ids(plan.ordered), [2, 1]);
    });

    test('la sugerida no cambia cuando el técnico elige otra, y se sabe que eligió', () {
      final visits = [_visit(1, km: 9), _visit(2, km: 2), _visit(3, km: 5)];
      final suggested = planRoute(visits, office: _at(0));
      expect(suggested.suggestedFirstId, 2);
      expect(suggested.isCustom, isFalse);

      final custom = planRoute(visits, office: _at(0), firstId: 1);
      expect(custom.suggestedFirstId, 2); // lo que sugeriría el algoritmo, no lo elegido
      expect(_ids(custom.ordered), [1, 3, 2]);
      expect(custom.isCustom, isTrue);
    });

    test('trae los km desde el punto anterior a cada visita', () {
      final plan = planRoute([_visit(1, km: 3), _visit(2, km: 10)], office: _at(0));
      expect(plan.legsKm[0]!, closeTo(3, 0.05));
      expect(plan.legsKm[1]!, closeTo(7, 0.05));
    });

    test('sin visitas pendientes, no hay sugerida', () {
      final plan = planRoute([_visit(1, km: 3, status: 'done')], office: _at(0));
      expect(plan.ordered, isEmpty);
      expect(plan.suggestedFirstId, isNull);
      expect(plan.isCustom, isFalse);
    });
  });

  group('las paradas que se pueden mirar', () {
    test('la visita en curso cuenta como parada, antes de las que faltan', () {
      final plan = planRoute([_visit(1, km: 5, status: 'en_route'), _visit(2, km: 2), _visit(3, km: 9)], office: _at(0));
      expect(_ids(plan.stops), [1, 2, 3]);
    });

    test('con una sola visita y yendo en camino a ella, todavía hay una parada', () {
      final plan = planRoute([_visit(1, km: 5, status: 'done'), _visit(2, km: 2, status: 'en_route')], office: _at(0));
      expect(plan.ordered, isEmpty); // ya no queda ninguna por hacer…
      expect(_ids(plan.stops), [2]); // …pero la que va en camino se puede ver en el mapa
    });

    test('sin visitas abiertas no hay paradas', () {
      final plan = planRoute([_visit(1, km: 5, status: 'done')], office: _at(0));
      expect(plan.stops, isEmpty);
    });
  });
}
