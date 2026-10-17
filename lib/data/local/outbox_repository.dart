import 'package:telyser_app/data/local/app_database.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import 'package:drift/drift.dart';


/// La cola de acciones. La app nunca envía directo al servidor: guarda aquí
/// y otro proceso envía cuando hay señal.
///
/// Estados: grace (10 s para deshacer, no enviable) -> pending -> sending -> failed.
class OutboxRepository {
  OutboxRepository(this._db, {DateTime Function()? now, Uuid? uuid})
    : _now = now ?? (() => DateTime.now().toUtc()),
      _uuid = uuid ?? const Uuid();

      final AppDatabase _db;
      final DateTime Function() _now; // se inyecta para poder probar el tiempo
      final Uuid _uuid;

  /// Guarda una acción en estado `grace`. Los segundos de gracia vienen de
  /// los parámetros del servidor (`undo_seconds`), nunca fijos en el código.
  Future<String> enqueue ({
    required String type,
    required int graceSeconds,
    int? visitId,
    Map<String, dynamic> payload = const {},

  }) async {
    final id = _uuid.v4();
    final now = _now();
    await _db.into(_db.outboxEvents).insert(
      OutboxEventsCompanion.insert(
        uuid: id, 
        type: type, 
        occurredAtUtc: now, // la hora del evento
        visitId: Value(visitId),
        payloadJson: Value(jsonEncode(payload)),
        state: const Value('grace'),
        graceUntilUtc: Value(now.add(Duration(seconds: graceSeconds)))
        ),
    );
    return id;
  }

  /// Deshacer = borrar la fila. Solo funciona si sigue en gracia.
  Future<bool> undo(String uuid) async {
    final n = await (_db.delete(_db.outboxEvents)
    ..where((e) =>
    e.uuid.equals(uuid) &
    e.state.equals('grace') &
    e.graceUntilUtc.isBiggerThanValue(_now())))
    .go();
    return n >0;
  }

  /// Pasa a `pending` las acciones cuyos segundos de gracia ya terminaron.
  Future<int> releaseExpired(){
    return (_db.update(_db.outboxEvents)
    ..where((e) =>
    e.state.equals('grace') &
    e.graceUntilUtc.isSmallerOrEqualValue(_now())))
    .write(const OutboxEventsCompanion(state: Value('pending')));
  }

  /// Lo que se puede enviar ahora, en orden. Se detiene en la primera acción
  /// que todavía está en gracia (o en vuelo) para no enviar nada "adelantado".
  Future<List<OutboxEvent>> nextBatch() async {
    final all = await (_db.select(_db.outboxEvents)
    ..orderBy([(e) => OrderingTerm.asc(e.seq)]))
    .get();
    final batch = <OutboxEvent>[];
    for (final e in all) {
      if( e.state == 'pending' || e.state == 'failed') {
        batch.add(e);
      } else {
        break;
      }
    }
    return batch;
  }

  /// Todas las acciones en orden. Se vuelve a emitir cada vez que la cola
  /// cambia (encolar, deshacer, liberar), y así la pantalla se actualiza sola.
  Stream<List<OutboxEvent>> watchAll() => (_db.select(_db.outboxEvents)
    ..orderBy([(e) => OrderingTerm.asc(e.seq)]))
    .watch();

  /// exists() revisa si ya existe una accion para no duplicar avisos y regresa valor booleano
  Future<bool> exists({required String type, required int visitId}) async {
    final row = await (_db.select(_db.outboxEvents) // consulta la tabla de la cola
          ..where((e) => e.type.equals(type) & e.visitId.equals(visitId)) // mismo tipo y misma visita
          ..limit(1)) // con una fila basta para saber que existe
        .getSingleOrNull(); // devuelve la fila o null si no hay ninguna
    return row != null;
  }
}

