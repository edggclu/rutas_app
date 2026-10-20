import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/domain/events/event_types.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/rules/technician_state.dart';
import 'package:telyser_app/domain/rules/visit_state.dart';

void main() {
  late DayRoute route; // 101, 102 y 103: todas Por hacer
  final t0 = DateTime.utc(2026, 10, 6, 14, 20);

  setUpAll(() {
    final raw = File('assets/mock/my_day.json').readAsStringSync();
    route = DayRoute.fromJson(json.decode(raw) as Map<String, dynamic>);
  });

  VisitEvent ev(String type, int visitId) =>
      VisitEvent(type: type, visitId: visitId, occurredAt: t0);
  VisitStatus st(DayRoute r, int id) =>
      r.visits.firstWhere((v) => v.id == id).status;

  test('sin acciones, la ruta queda igual', () {
    final r = applyEvents(route, const []);
    expect(st(r, 101), VisitStatus.pending);
    expect(st(r, 102), VisitStatus.pending);
  });

  test('confirmar la salida pone la primera visita En camino', () {
    final r = applyEvents(route, [ev(EventTypes.departureConfirmed, 101)]);
    expect(st(r, 101), VisitStatus.enRoute);
    expect(st(r, 102), VisitStatus.pending);
    expect(computeTechnicianState(r.visits).label, 'En camino a Hotel Bahía');
  });

  test('Llegué pone En sitio y guarda la hora', () {
    final r = applyEvents(route, [
      ev(EventTypes.departureConfirmed, 101),
      ev(EventTypes.arrived, 101),
    ]);
    expect(st(r, 101), VisitStatus.onSite);
    expect(r.visits.first.arrivedAt, t0);
    expect(computeTechnicianState(r.visits).label, 'En sitio en Hotel Bahía');
  });

  test('al terminar, la visita queda Hecha y la siguiente En camino', () {
    final r = applyEvents(route, [
      ev(EventTypes.departureConfirmed, 101),
      ev(EventTypes.arrived, 101),
      ev(EventTypes.finished, 101),
    ]);
    expect(st(r, 101), VisitStatus.done);
    expect(r.visits.first.result, VisitResult.finished);
    expect(st(r, 102), VisitStatus.enRoute);
  });

  test('cada resultado cierra la visita con el resultado correcto', () {
    VisitResult? resultOf(String closing) => applyEvents(route, [
          ev(EventTypes.departureConfirmed, 101),
          ev(EventTypes.arrived, 101),
          ev(closing, 101),
        ]).visits.first.result;

    expect(resultOf(EventTypes.continueTomorrow), VisitResult.continueLater);
    expect(resultOf(EventTypes.blocked), VisitResult.blocked);
    expect(resultOf(EventTypes.noAnswerConfirmed), VisitResult.noAnswer);
  });

  test('"No me abren" solo avisa: la visita sigue En sitio', () {
    final r = applyEvents(route, [
      ev(EventTypes.departureConfirmed, 101),
      ev(EventTypes.arrived, 101),
      ev(EventTypes.noAnswerReported, 101),
    ]);
    expect(st(r, 101), VisitStatus.onSite);
  });

  test('fuera de orden: no se arranca otra visita si ya hay una En camino', () {
    final r = applyEvents(route, [
      ev(EventTypes.departureConfirmed, 101),
      ev(EventTypes.arrived, 103),
      ev(EventTypes.finished, 103),
    ]);
    expect(st(r, 103), VisitStatus.done);
    expect(st(r, 101), VisitStatus.enRoute); // sigue igual
    expect(st(r, 102), VisitStatus.pending); // no se adelanta
  });

  test('al cerrar la última visita, el técnico queda Libre', () {
    final r = applyEvents(route, [
      ev(EventTypes.departureConfirmed, 101),
      ev(EventTypes.arrived, 101),
      ev(EventTypes.finished, 101),
      ev(EventTypes.arrived, 102),
      ev(EventTypes.noAnswerConfirmed, 102),
      ev(EventTypes.arrived, 103),
      ev(EventTypes.finished, 103),
    ]);
    expect(computeTechnicianState(r.visits).kind, TechStateKind.free);
  });

  test('acciones de una visita que no está en la ruta se ignoran', () {
    final r = applyEvents(route, [ev(EventTypes.arrived, 999)]);
    expect(st(r, 101), VisitStatus.pending);
  });
}