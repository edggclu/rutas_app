import 'package:telyser_app/domain/models/event_models.dart';

import '../domain/models/enums.dart';
import '../domain/events/event_data.dart';
import '../domain/models/models.dart';
import 'action_receipt.dart';
import 'outbox_writer.dart';

/// Acciones de la Salida (inicio del día).
class DepartureActions { // una clase por área
  DepartureActions(this._writer); // recibe el ayudante

  final OutboxWriter _writer; // escribe en la cola

  /// "Llevo todo" / salir con faltantes. Encola, en este orden:
  ///  1. un `MissingItemsEvent` por cada visita con renglones faltantes;
  ///  2. un `DepartureConfirmedEvent` de la primera visita por hacer.
  Future<ActionReceipt> confirmDeparture({ // devuelve el comprobante
    required List<Visit> visits, // las visitas de la ruta
    required Map<int, List<ChecklistItem>> missing, // id de visita -> renglones que faltan
  }) async {
    final first = visits.firstWhere((v) => v.status == VisitStatus.pending); // primera visita por hacer
    return _writer.undoable([ // todo comparte un solo comprobante
      for (final entry in missing.entries) // por cada visita con faltantes
        PendingEvent( // aviso de faltantes
          MissingItemsEvent([ // la lista de renglones que faltan
            for (final i in entry.value) MissingItem(id: i.id, text: i.text, kind: i.kind), // cada renglón
          ]),
          visitId: entry.key, // de qué visita es
        ),
      PendingEvent(const DepartureConfirmedEvent(), visitId: first.id), // la salida va después de los faltantes
    ]);
  }
}