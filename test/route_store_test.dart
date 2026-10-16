import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/data/local/route_store.dart';

void main() {
  late AppDatabase db;
  late RouteStore store;
  late Map<String, dynamic> raw;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = RouteStore(db);
    raw = json.decode(File('assets/mock/my_day.json').readAsStringSync())
        as Map<String, dynamic>;
  });

  tearDown(() => db.close());

  test('lo guardado se lee igual (funciona sin señal)', () async {
    await store.saveDay(raw);
    final back = await store.loadDay('2026-10-06');
    expect(back!.visits.length, 3);
    expect(back.visits.first.job.folio, 'TEL-2610-014');
    expect(back.visits.first.client.overdue, isTrue);
  });

  test('las columnas consultables se llenan', () async {
    await store.saveDay(raw);
    final rows = await db.select(db.cachedVisits).get();
    expect(rows.map((r) => r.status), ['pending', 'pending', 'pending']);
    expect(rows.map((r) => r.orderInRoute), [1, 2, 3]);
  });

  test('guardar de nuevo reemplaza la ruta anterior', () async {
    await store.saveDay(raw);
    raw['visits'] = (raw['visits'] as List).take(1).toList();
    await store.saveDay(raw);
    expect((await store.loadDay('2026-10-06'))!.visits.length, 1);
  });

  test('una fecha que no se guardó devuelve null', () async {
    await store.saveDay(raw);
    expect(await store.loadDay('2026-10-07'), isNull);
  });
}