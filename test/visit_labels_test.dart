import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/visit_labels.dart';

void main() {
  late Visit visit;

  setUp(() {
    final raw = json.decode(File('assets/mock/my_day.json').readAsStringSync()) as Map<String, dynamic>;
    visit = DayRoute.fromJson(raw).visits.first; // la visita 101: Día 1
  });

  test('las visitas abiertas dicen su estado', () {
    expect(visitStatusLabel(visit), 'Por hacer');
    expect(visitStatusLabel(visit.copyWith(status: VisitStatus.enRoute)), 'En camino');
    expect(visitStatusLabel(visit.copyWith(status: VisitStatus.onSite)), 'En sitio');
  });

  test('terminar la deja Hecha', () {
    expect(visitStatusLabel(visit.copyWith(status: VisitStatus.done, result: VisitResult.finished)), 'Hecha');
  });

  test('"Sigo otro día" no es Hecha: queda Sin terminar con el número de día', () {
    final v = visit.copyWith(status: VisitStatus.done, result: VisitResult.continueLater);
    expect(visitStatusLabel(v), 'Sin terminar · Día 1');
  });

  test('"No pude seguir" y "No me atendieron" tampoco son Hecha', () {
    expect(visitStatusLabel(visit.copyWith(status: VisitStatus.done, result: VisitResult.blocked)), 'Detenida');
    expect(visitStatusLabel(visit.copyWith(status: VisitStatus.done, result: VisitResult.noAnswer)), 'Sin atender');
  });
}
