import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/rules/technician_state.dart';

void main() {
  late DayRoute route;

  setUpAll(() {
    final raw = File('assets/mock/my_day.json').readAsStringSync();
    route = DayRoute.fromJson(json.decode(raw) as Map<String, dynamic>);
  });

  test('my_day.json se parece al contrato', () {
    expect(route.visits.length, 3);
    expect(route.visits.first.job.folio, 'TEL-2610-014');
    expect(route.visits.first.job.type, JobType.installation);
    expect(route.visits[1].job.coverage, Coverage.warranty);
    expect(route.visits.first.client.overdue, isTrue);
    expect(route.visits.first.place.contact?.authorized, isTrue);
  });

  test('las visitas llegan ordenadas y la hora viene en UTC', () {
    final orders = route.visits.map((v) => v.order).toList();
    expect(orders, [1, 2, 3]);
    expect(route.visits.first.scheduledAt!.isUtc, isTrue);
  });

  test('el estado del técnico se calcula de sus visitas', () {
    // Antes de salir, todas Por hacer: Libre.
    expect(computeTechnicianState(route.visits).kind, TechStateKind.free);

    final enRoute = [
      route.visits.first.copyWith(status: VisitStatus.enRoute),
      ...route.visits.skip(1),
    ];
    final s = computeTechnicianState(enRoute);
    expect(s.kind, TechStateKind.enRoute);
    expect(s.label, 'En camino a Hotel Bahía');
    expect(computeTechnicianState(const []).kind, TechStateKind.free);
  });

  test('el checklist de la visita 101 viene del plan', () {
    final c = route.visits.first.checklist;
    expect(c.source, ChecklistSource.plan);
    expect(c.materials.length, 3);
    expect(c.tools.single.text, 'Escalera de 6 m');
    expect(c.materials[1].quantityLabel, 'x120');
    expect(route.visits[1].checklist.source, ChecklistSource.none);
  });

  test('el ingeniero trae su teléfono', () { // para pedir ayuda por WhatsApp
    expect(route.visits.first.job.engineer?.phone, '3220000002'); // teléfono del mock
  });
}
