import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:telyser_app/data/osrm_routing_repository.dart';
import 'package:telyser_app/data/repositories.dart';
import 'package:telyser_app/domain/models/geo_point.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/models/route_path.dart';
import 'package:telyser_app/domain/rules/route_planner.dart';
import 'package:telyser_app/providers/routing_providers.dart';

/// Una respuesta de OSRM con dos tramos (3 puntos). OSRM da [longitud, latitud] y metros.
const _osrm = {
  'code': 'Ok',
  'routes': [
    {
      'geometry': {
        'coordinates': [
          [-105.20, 20.60],
          [-105.21, 20.61],
          [-105.22, 20.62],
        ],
      },
      'legs': [
        {'distance': 1500.0},
        {'distance': 2250},
      ],
    },
  ],
};

class _FakeRouting implements RoutingRepository {
  _FakeRouting({this.fail = false});

  final bool fail;
  int calls = 0;

  @override
  Future<RoutePath?> route(List<GeoPoint> stops) async {
    calls++;
    if (fail) throw Exception('sin señal');
    return RoutePath(points: stops, legsKm: [for (var i = 1; i < stops.length; i++) 2.0]);
  }
}

Visit _visit(int id, double km) => Visit.fromJson({
      'id': id,
      'order': id,
      'status': 'pending',
      'client': {'id': id, 'name': 'Cliente $id', 'overdue': false},
      'place': {'id': id, 'name': 'Lugar $id', 'address': '', 'lat': 20.0 + km * 0.009, 'lng': -105.0},
      'job': {'id': id, 'folio': 'TEL-$id'},
    });

void main() {
  group('lector de la respuesta de OSRM', () {
    test('invierte longitud y latitud y pasa los metros a km', () {
      final path = parseOsrmRoute(_osrm)!;
      expect(path.points.first, const GeoPoint(20.60, -105.20));
      expect(path.points.length, 3);
      expect(path.legsKm, [1.5, 2.25]);
    });

    test('sin ruta, devuelve null', () {
      expect(parseOsrmRoute({'code': 'NoRoute'}), isNull);
      expect(parseOsrmRoute({'code': 'Ok', 'routes': []}), isNull);
      expect(parseOsrmRoute({'code': 'Ok', 'routes': [{'geometry': 'raro'}]}), isNull);
    });

    test('ignora coordenadas rotas y exige al menos dos puntos', () {
      final bad = {
        'code': 'Ok',
        'routes': [
          {
            'geometry': {'coordinates': [[-105.2, 20.6], 'x', [1]]},
          },
        ],
      };
      expect(parseOsrmRoute(bad), isNull); // quedó un solo punto bueno
    });

    test('si faltan los tramos, la línea sirve igual', () {
      final noLegs = {
        'code': 'Ok',
        'routes': [
          {
            'geometry': {
              'coordinates': [
                [-105.20, 20.60],
                [-105.21, 20.61],
              ],
            },
          },
        ],
      };
      expect(parseOsrmRoute(noLegs)!.legsKm, isEmpty);
    });
  });

  group('cliente de OSRM', () {
    test('pide la ruta con longitud primero y la lee', () async {
      late Uri asked;
      final repo = OsrmRoutingRepository(
        'https://osrm.test/',
        client: MockClient((req) async {
          asked = req.url;
          return http.Response(json.encode(_osrm), 200);
        }),
      );
      final path = await repo.route(const [GeoPoint(20.60, -105.20), GeoPoint(20.62, -105.22)]);
      expect(asked.toString(), 'https://osrm.test/route/v1/driving/-105.2,20.6;-105.22,20.62?overview=full&geometries=geojson');
      expect(path!.legsKm.length, 2);
    });

    test('un error del servidor devuelve null', () async {
      final repo = OsrmRoutingRepository('https://osrm.test', client: MockClient((req) async => http.Response('x', 500)));
      expect(await repo.route(const [GeoPoint(1, 1), GeoPoint(2, 2)]), isNull);
    });

    test('con un solo punto no pide nada', () async {
      var asked = false;
      final repo = OsrmRoutingRepository('https://osrm.test', client: MockClient((req) async {
        asked = true;
        return http.Response('{}', 200);
      }));
      expect(await repo.route(const [GeoPoint(1, 1)]), isNull);
      expect(asked, isFalse);
    });
  });

  group('puntos y tramos de la ruta', () {
    test('los mismos puntos son iguales (para no volver a pedir el trayecto)', () {
      const a = RouteStops([GeoPoint(1, 1), GeoPoint(2, 2)]);
      const b = RouteStops([GeoPoint(1, 1), GeoPoint(2, 2)]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == const RouteStops([GeoPoint(1, 1), GeoPoint(2, 3)]), isFalse);
    });

    test('stopPoints trae la salida y las visitas con ubicación', () {
      final plan = planRoute([_visit(1, 9), _visit(2, 2)], office: const GeoPoint(20.0, -105.0));
      expect(plan.stopPoints.length, 3); // oficina + 2 visitas
      expect(plan.stopPoints.first, const GeoPoint(20.0, -105.0));
    });

    test('legKm usa los km por calles y, si no hay, la línea recta', () {
      final plan = planRoute([_visit(1, 9), _visit(2, 2)], office: const GeoPoint(20.0, -105.0));
      const path = RoutePath(points: [], legsKm: [3.1, 7.4]);
      expect(plan.legKm(0, path), 3.1);
      expect(plan.legKm(1, path), 7.4);
      expect(plan.legKm(0, null), plan.legsKm[0]); // sin servicio: la distancia recta
    });

    test('sin punto de salida, la primera visita no tiene tramo', () {
      final plan = planRoute([_visit(1, 9), _visit(2, 2)]); // sin oficina
      const path = RoutePath(points: [], legsKm: [6.0]);
      expect(plan.legKm(0, path), isNull);
      expect(plan.legKm(1, path), 6.0);
    });
  });

  group('provider de la ruta por calles', () {
    const stops = RouteStops([GeoPoint(1, 1), GeoPoint(2, 2)]);

    ProviderContainer container(RoutingRepository? repo) {
      final c = ProviderContainer(overrides: [routingRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      return c;
    }

    test('con servicio, trae la ruta', () async {
      final c = container(_FakeRouting());
      expect((await c.read(routePathProvider(stops).future))!.legsKm, [2.0]);
    });

    test('sin servicio configurado, null (se dibuja la línea recta)', () async {
      expect(await container(null).read(routePathProvider(stops).future), isNull);
    });

    test('si falla (sin señal), null y no truena', () async {
      expect(await container(_FakeRouting(fail: true)).read(routePathProvider(stops).future), isNull);
    });

    test('los mismos puntos no se piden dos veces', () async {
      final repo = _FakeRouting();
      final c = container(repo);
      final keep = c.listen(routePathProvider(stops), (previous, next) {}); // lo mantiene vivo
      await c.read(routePathProvider(stops).future);
      await c.read(routePathProvider(const RouteStops([GeoPoint(1, 1), GeoPoint(2, 2)])).future);
      expect(repo.calls, 1);
      keep.close();
    });
  });
}
