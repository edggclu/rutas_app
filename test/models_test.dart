import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/enums.dart';
import 'package:telyser_app/domain/models.dart';
import 'package:telyser_app/domain/technician_state.dart';

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
    final s = computeTechnicianState(route.visits);
    expect(s.kind, TechStateKind.enRoute);
    expect(s.label, 'En camino a Hotel Bahía');
    expect(computeTechnicianState(const []).kind, TechStateKind.free);
  });
}
