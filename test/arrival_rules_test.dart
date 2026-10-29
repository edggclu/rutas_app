import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/arrival_rules.dart';
import 'package:telyser_app/domain/events/event_types.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/rules/visit_state.dart';

void main() {
  late DayRoute route; // 101, 102 y 103: todas Por hacer
  final t0 = DateTime.utc(2026, 10, 6, 14, 20); // hora fija de prueba

  setUpAll(() { // se ejecuta una vez
    final raw = File('assets/mock/my_day.json').readAsStringSync(); // lee el JSON de prueba
    route = DayRoute.fromJson(json.decode(raw) as Map<String, dynamic>); // lo convierte en ruta
  });

  VisitEvent ev(String type, int visitId) => // atajo para crear acciones de la cola
      VisitEvent(type: type, visitId: visitId, occurredAt: t0); // con la hora fija

  ArrivalBlock? blockOf(DayRoute r, int id) => // atajo: ¿por qué no puede marcar Llegué en esa visita?
      arrivalBlock(r.visits.firstWhere((v) => v.id == id), r.visits); // aplica la regla

  test('antes de confirmar la salida no se puede marcar Llegué en ninguna', () { // ruta sin iniciar
    expect(blockOf(route, 101), ArrivalBlock.routeNotStarted); // primera visita
    expect(blockOf(route, 102), ArrivalBlock.routeNotStarted); // segunda
    expect(blockOf(route, 103), ArrivalBlock.routeNotStarted); // tercera
    expect(visitInProgress(route.visits), isNull); // ninguna en curso
  });

  test('con la salida confirmada, solo se puede en la visita En camino', () { // ruta iniciada
    final r = applyEvents(route, [ev(EventTypes.departureConfirmed, 101)]); // confirma la salida
    expect(blockOf(r, 101), isNull); // la visita a la que va: sí
    expect(blockOf(r, 102), ArrivalBlock.anotherVisitInProgress); // otra: no
    expect(blockOf(r, 103), ArrivalBlock.anotherVisitInProgress); // otra: no
    expect(visitInProgress(r.visits)?.id, 101); // la que está en curso
  });

  test('mientras está En sitio en una, no puede marcar Llegué en otra', () { // visita en curso
    final r = applyEvents(route, [ // salida y llegada
      ev(EventTypes.departureConfirmed, 101),
      ev(EventTypes.arrived, 101),
    ]);
    expect(blockOf(r, 102), ArrivalBlock.anotherVisitInProgress); // la siguiente sigue bloqueada
    expect(blockOf(r, 101), isNull); // la actual ya no aplica
  });

  test('al cerrar una visita, hay que salir a la siguiente antes de marcar Llegué', () { // ya no avanza sola
    final closed = [ // salida, llegada y cierre
      ev(EventTypes.departureConfirmed, 101),
      ev(EventTypes.arrived, 101),
      ev(EventTypes.finished, 101),
    ];
    final r = applyEvents(route, closed);
    expect(blockOf(r, 102), ArrivalBlock.routeNotStarted); // todavía no sale a ninguna
    expect(blockOf(r, 103), ArrivalBlock.routeNotStarted); // tampoco a la 103
    final next = applyEvents(route, [...closed, ev(EventTypes.departureConfirmed, 102)]); // sale a la 102
    expect(blockOf(next, 102), isNull); // ahora sí
    expect(blockOf(next, 103), ArrivalBlock.anotherVisitInProgress);
  });
}
