import '../domain/enums.dart'; // VisitStatus
import '../domain/event_types.dart'; // nombres de los eventos
import '../domain/models.dart'; // Visit y ChecklistItem
import 'action_receipt.dart'; // el comprobante
import 'outbox_writer.dart'; // el ayudante que escribe en la cola

/// Acciones de la Salida (inicio del día).
class DepartureActions { // una clase por área
  DepartureActions(this._writer); // recibe el ayudante

  final OutboxWriter _writer; // escribe en la cola

  /// "Llevo todo" / salir con faltantes. Encola, en este orden:
  ///  1. un `missing_items` por cada visita con renglones faltantes;
  ///  2. un `departure_confirmed` de la primera visita por hacer.
  Future<ActionReceipt> confirmDeparture({ // devuelve el comprobante
    required List<Visit> visits, // las visitas de la ruta
    required Map<int, List<ChecklistItem>> missing, // id de visita -> renglones que faltan
  }) async {
    final first = visits.firstWhere((v) => v.status == VisitStatus.pending); // primera visita por hacer
    return _writer.undoable([ // todo comparte un solo comprobante
      for (final entry in missing.entries) // por cada visita con faltantes
        PendingEvent( // aviso de faltantes
          EventTypes.missingItems, // tipo: "me falta material"
          visitId: entry.key, // de qué visita es
          payload: { // los datos del evento
            'items': [ // la lista de renglones que faltan
              for (final i in entry.value) // por cada renglón faltante
                {'id': i.id, 'text': i.text, 'kind': i.kind.name}, // su id, su texto y su tipo
            ],
          },
        ),
      PendingEvent(EventTypes.departureConfirmed, visitId: first.id), // la salida va después de los faltantes
    ]);
  }
} 