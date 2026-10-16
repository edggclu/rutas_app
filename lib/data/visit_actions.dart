import 'package:telyser_app/data/local/outbox_repository.dart';
import 'package:telyser_app/domain/enums.dart';
import 'package:telyser_app/domain/event_types.dart';
import 'package:telyser_app/domain/models.dart';

/// Comprobante de lo que se encoló: sirve para deshacerlo.
class ActionReceipt {

  /// Identificadores de las filas creadas en la cola.
  final List<String> uuids;

  // Segundos que dura el tiempo para deshacer (parametro 'undo_seconds')
  final int graceSeconds;

  const ActionReceipt(this.uuids, this.graceSeconds);
}

/// Acciones del tecnico. Cada metodo guarda eventos en la cola (en estado
/// 'grace') y devuelve un comprobante.
class VisitActions {

  final OutboxRepository _outbox;

  /// Lee 'undo_seconds' de los parametros. Se inyecta para poder probar sin pantallas ni Riverpod.
  final Future<int> Function() _graceSeconds;

  VisitActions(this._outbox, this._graceSeconds);

  /// "Llevo todo" / salir con faltantes
  /// 
  /// Encola, en este orden:
  /// 1. un 'missing_items' por cada visita que tenga renglones faltantes
  /// 2. un 'departure_confirmed' de la primera visita por hacer.
  /// 
  /// [missing] es id: de visita -> renglones que faltan.
  Future<ActionReceipt> confirmDeparture({
    required List<Visit> visits,
    required Map<int, List<ChecklistItem>> missing,
  }) async {
    final grace = await _graceSeconds();
    final first = visits.firstWhere((v) => v.status == VisitStatus.pending);
    final uuids = <String>[];

    for (final entry in missing.entries) {
      uuids.add(await _outbox.enqueue(
        type: EventTypes.missingItems, graceSeconds: grace,
        visitId: entry.key,
        payload: {
          'items': [
            for (final i in entry.value) {
              'id': i.id, 'text': i.text, 'kind': i.kind.name
            }
          ]
        }
      ));
    }
    uuids.add(await _outbox.enqueue(
      type: EventTypes.departureConfirmed, 
      graceSeconds: grace,
      visitId: first.id));

      return ActionReceipt(uuids, grace);
  }

  /// Deshace todo lo que contiene el comprobante. Cada fila se borra solo si
  /// sigue en gracia; pasado el tiempo ya no se puede.
  Future<void> undo(ActionReceipt receipt) async {
    for (final id in receipt.uuids) {
      await _outbox.undo(id);
    }
  }
}