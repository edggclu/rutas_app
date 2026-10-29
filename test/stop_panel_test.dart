import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/models/geo_point.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/rules/route_planner.dart';
import 'package:telyser_app/features/route/widgets/stop_panel.dart';

Visit _visit(int id, double km, String status) => Visit.fromJson({
      'id': id,
      'order': id,
      'status': status,
      'client': {'id': id, 'name': 'Cliente $id', 'overdue': false, 'tier': 'A'},
      'place': {'id': id, 'name': 'Lugar $id', 'address': 'Calle $id', 'lat': 20.0 + km * 0.009, 'lng': -105.0},
      'job': {'id': id, 'folio': 'TEL-$id'},
    });

Widget _panel(RoutePlan plan) => MaterialApp(
      home: Scaffold(
        body: StopPanel(
          plan: plan,
          path: null,
          stop: plan.stops.firstOrNull,
          onSelect: (v) {},
          onNavigate: () {},
          onStartHere: () {},
          onDetail: () {},
          onResetRoute: () {},
        ),
      ),
    );

void main() {
  const office = GeoPoint(20.0, -105.0);

  testWidgets('yendo en camino a la última visita, el mapa la muestra y no dice que ya cerró todo', (tester) async {
    final plan = planRoute([_visit(1, 5, 'done'), _visit(2, 2, 'en_route')], office: office);
    await tester.pumpWidget(_panel(plan));
    expect(find.text('Ya cerraste todas tus visitas.'), findsNothing);
    expect(find.text('EN CAMINO'), findsOneWidget);
    expect(find.text('Cliente 2'), findsOneWidget);
    expect(find.text('Iniciar navegación'), findsOneWidget); // todavía puede abrir la navegación
    expect(find.text('Detalle de visita'), findsOneWidget);
    expect(find.text('Empezar por esta'), findsNothing); // no tiene sentido rehacer la ruta
  });

  testWidgets('estando en sitio, solo queda el detalle', (tester) async {
    final plan = planRoute([_visit(1, 5, 'done'), _visit(2, 2, 'on_site')], office: office);
    await tester.pumpWidget(_panel(plan));
    expect(find.text('EN SITIO'), findsOneWidget);
    expect(find.text('Iniciar navegación'), findsNothing);
    expect(find.text('Detalle de visita'), findsOneWidget);
  });

  testWidgets('con todas cerradas sí dice que ya cerró todo', (tester) async {
    final plan = planRoute([_visit(1, 5, 'done'), _visit(2, 2, 'done')], office: office);
    await tester.pumpWidget(_panel(plan));
    expect(find.text('Ya cerraste todas tus visitas.'), findsOneWidget);
  });

  testWidgets('con una en curso y otras por hacer, se puede elegir entre ellas', (tester) async {
    final plan = planRoute([_visit(1, 5, 'en_route'), _visit(2, 2, 'pending'), _visit(3, 9, 'pending')], office: office);
    await tester.pumpWidget(_panel(plan));
    expect(find.text('EN CAMINO'), findsOneWidget); // empieza mirando la que va en camino
    expect(find.text('1'), findsOneWidget); // y los números de las que faltan están a la vista
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('con visitas por hacer y ninguna en curso, la siguiente parada', (tester) async {
    final plan = planRoute([_visit(1, 5, 'pending'), _visit(2, 2, 'pending')], office: office);
    await tester.pumpWidget(_panel(plan));
    expect(find.text('SIGUIENTE PARADA'), findsOneWidget);
    expect(find.text('Cliente 2'), findsOneWidget); // la más cercana a la oficina
  });
}
