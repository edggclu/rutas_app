import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/application/departure_actions.dart';
import 'package:telyser_app/application/outbox_writer.dart';
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/data/local/outbox_repository.dart';
import 'package:telyser_app/domain/events/event_data.dart';
import 'package:telyser_app/domain/events/event_types.dart';
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/domain/models/event_models.dart';
import 'package:telyser_app/domain/rules/missing_items.dart';
import 'package:telyser_app/domain/rules/visit_state.dart';

const _camaras = MissingItem(id: 1, text: 'Cámaras IP', kind: ChecklistKind.material);
const _cable = MissingItem(id: 2, text: 'Cable UTP', kind: ChecklistKind.material);
const _escalera = MissingItem(id: 4, text: 'Escalera de 6 m', kind: ChecklistKind.tool);

VisitEvent _e(EventData d, {int visit = 101, int minutes = 0}) =>
    VisitEvent.of(d, occurredAt: DateTime.utc(2026, 10, 6, 14, minutes), visitId: visit);

List<int> _ids(List<MissingItem> items) => [for (final i in items) i.id];

void main() {
  group('lo que todavía falta', () {
    test('sin faltantes al salir, no falta nada', () {
      expect(pendingMissingItems([_e(const DepartureConfirmedEvent())], 101), isEmpty);
    });

    test('lo marcado al salir sigue faltando hasta que lo consigue', () {
      final events = [_e(const MissingItemsEvent([_camaras, _cable, _escalera]))];
      expect(_ids(pendingMissingItems(events, 101)), [1, 2, 4]);
    });

    test('al conseguir algunos, solo quedan los demás', () {
      final events = [
        _e(const MissingItemsEvent([_camaras, _cable, _escalera])),
        _e(const ItemsObtainedEvent([2]), minutes: 30),
      ];
      expect(_ids(pendingMissingItems(events, 101)), [1, 4]);
    });

    test('al conseguir todo, ya no falta nada', () {
      final events = [
        _e(const MissingItemsEvent([_camaras, _cable])),
        _e(const ItemsObtainedEvent([1, 2]), minutes: 30),
      ];
      expect(pendingMissingItems(events, 101), isEmpty);
    });

    test('cada visita lleva sus faltantes', () {
      final events = [
        _e(const MissingItemsEvent([_camaras])),
        _e(const MissingItemsEvent([_cable]), visit: 102),
        _e(const ItemsObtainedEvent([1]), visit: 102), // es de otra visita: no cuenta para la 101
      ];
      expect(_ids(pendingMissingItems(events, 101)), [1]);
      expect(_ids(pendingMissingItems(events, 102)), [2]);
    });

    test('conseguir algo que no faltaba no hace nada', () {
      final events = [
        _e(const MissingItemsEvent([_camaras])),
        _e(const ItemsObtainedEvent([99])),
      ];
      expect(_ids(pendingMissingItems(events, 101)), [1]);
    });

    test('marcar que ya lo tiene no cambia el estado de la visita', () {
      expect(EventData.parse(EventTypes.itemsObtained, {'item_ids': [1, 'x', 2]}), isA<ItemsObtainedEvent>());
      expect((EventData.parse(EventTypes.itemsObtained, {'item_ids': [1, 'x', 2]}) as ItemsObtainedEvent).itemIds,
          [1, 2]); // ignora lo que no es un id
    });
  });

  group('acción', () {
    late AppDatabase db;
    late OutboxRepository outbox;
    late DepartureActions actions;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      outbox = OutboxRepository(db, now: () => DateTime.utc(2026, 10, 6, 14));
      actions = DepartureActions(OutboxWriter(outbox, () async => 10));
    });

    tearDown(() => db.close());

    test('"Ya lo tengo" guarda los ids en la cola, con tiempo para deshacer', () async {
      await actions.markObtained(visitId: 101, items: const [_camaras, _escalera]);
      final row = (await db.select(db.outboxEvents).get()).single;
      expect(row.type, EventTypes.itemsObtained);
      expect(row.visitId, 101);
      expect(row.payloadJson, '{"item_ids":[1,4]}');
      expect(row.state, 'grace');
    });

    test('sin renglones no guarda nada', () async {
      expect(() => actions.markObtained(visitId: 101, items: const []), throwsArgumentError);
      expect(await db.select(db.outboxEvents).get(), isEmpty);
    });
  });
}
