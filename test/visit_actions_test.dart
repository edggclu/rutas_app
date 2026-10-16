import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/data/local/outbox_repository.dart';
import 'package:telyser_app/data/visit_actions.dart';
import 'package:telyser_app/domain/event_types.dart';
import 'package:telyser_app/domain/models.dart';

void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late VisitActions actions;
  late List<Visit> visits;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    outbox = OutboxRepository(db, now: () => DateTime.utc(2026, 10, 6, 12));
    actions = VisitActions(outbox, () async => 10);
    final raw = File('assets/mock/my_day.json').readAsStringSync();
    visits =
        DayRoute.fromJson(json.decode(raw) as Map<String, dynamic>).visits;
  });

  tearDown(() => db.close());

  test('salida sin faltantes: solo encola la salida, en gracia', () async {
    final receipt = await actions.confirmDeparture(visits: visits, missing: {});
    final rows = await db.select(db.outboxEvents).get();

    expect(rows.map((e) => e.type), [EventTypes.departureConfirmed]);
    expect(rows.single.visitId, 101);
    expect(rows.single.state, 'grace');
    expect(receipt.graceSeconds, 10);
    expect(await outbox.nextBatch(), isEmpty); // aún no es enviable
  });

  test('con faltantes: el aviso va ANTES que la salida', () async {
    final tools = visits.first.checklist.tools;
    await actions.confirmDeparture(visits: visits, missing: {101: tools});
    final rows = await db.select(db.outboxEvents).get();

    expect(rows.map((e) => e.type),
        [EventTypes.missingItems, EventTypes.departureConfirmed]);
    final items = (jsonDecode(rows.first.payloadJson)['items']) as List;
    expect(items.single['text'], 'Escalera de 6 m');
    expect(items.single['kind'], 'tool');
  });

  test('deshacer borra todo lo que se encoló', () async {
    final tools = visits.first.checklist.tools;
    final receipt =
        await actions.confirmDeparture(visits: visits, missing: {101: tools});
    await actions.undo(receipt);
    expect(await db.select(db.outboxEvents).get(), isEmpty);
  });
}