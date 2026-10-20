import '../domain/events/event_data.dart'; // los eventos
import '../domain/extras.dart'; // ExtraDraft, ExtraItem, ExtraOutcome, RequestOrigin, decideExtra, quantityText
import '../domain/models.dart'; // Visit
import 'action_receipt.dart'; // el comprobante
import 'outbox_writer.dart'; // el ayudante que escribe en la cola

/// Resultado de guardar un extra: qué decidió la app y el comprobante para deshacer.
class ExtraResult { // lo que devuelve addExtra
  const ExtraResult(this.outcome, this.receipt); // constructor
  final ExtraOutcome outcome; // qué se decidió (se hizo, o quedó como solicitud)
  final ActionReceipt receipt; // para poder deshacer
}

/// Acciones de extras y solicitudes para después.
class ExtrasActions { // una clase por área
  ExtrasActions(this._writer); // recibe el ayudante

  final OutboxWriter _writer; // escribe en la cola

  /// Convierte lo que se llenó en el formulario en los datos que se guardan.
  ExtraItem _item(ExtraDraft d, Visit visit) => ExtraItem( // el renglón del extra
        name: d.name, // nombre
        productId: d.productId, // id del catálogo (null si lo escribió)
        quantity: d.quantity, // cantidad
        unit: d.unit, // unidad
        source: d.source, // de dónde salió
        reason: d.reason, // por qué
        requestedByAuthorized: d.requestedByAuthorized, // quién lo pidió
        requesterName: d.requestedByAuthorized ? visit.place.contact?.name : null, // nombre del contacto, si fue él
        notInstalled: d.notInstalled, // ¿es "no se instaló"?
      );

  /// Guarda un extra aplicando las reglas del negocio.
  Future<ExtraResult> addExtra({required Visit visit, required ExtraDraft draft}) async { // visita y formulario llenado
    final outcome = decideExtra( // aplica las reglas
      requestedByAuthorized: draft.requestedByAuthorized, // ¿lo pidió el contacto autorizado?
      clientOverdue: visit.client.overdue, // ¿el cliente tiene saldo vencido?
      isEquipment: draft.isEquipment, // ¿es equipo?
      notInstalled: draft.notInstalled, // ¿es "no se instaló"?
    );
    final item = _item(draft, visit); // los datos del extra
    final events = <PendingEvent>[]; // los eventos que habrá que guardar

    if (outcome == ExtraOutcome.register) { // se hace y se anota
      events.add(PendingEvent(ExtraAddedEvent(item), visitId: visit.id)); // el extra
      final minutes = draft.delayMinutes; // retraso estimado
      if (minutes != null && minutes > 0) { // si va a retrasar las siguientes visitas
        events.add(PendingEvent( // aviso al jefe
          RouteDelayReportedEvent(minutes: minutes, extraName: draft.name), // cuánto y por qué extra
          visitId: visit.id, // visita
        ));
      }
    } else { // no se hace: queda como solicitud para después
      events.add(PendingEvent( // la solicitud
        RequestAddedEvent(
          description: '${quantityText(draft.quantity)} × ${draft.name}', // texto para administración
          origin: outcome == ExtraOutcome.laterOtherPerson // por qué quedó como solicitud
              ? RequestOrigin.otherPerson // la pidió otra persona
              : RequestOrigin.creditHold, // el cliente tiene saldo vencido
          item: item, // los datos del extra
        ),
        visitId: visit.id, // visita
      ));
    }
    final receipt = await _writer.undoable(events); // guarda todo con un solo comprobante
    return ExtraResult(outcome, receipt); // devuelve qué pasó y cómo deshacerlo
  }

  /// Guarda una solicitud para después (lo que no se puede hacer en esta visita).
  Future<ActionReceipt> addRequest({ // devuelve el comprobante para deshacer
    required int visitId, // visita
    required String description, // qué pidió el cliente
    String? requestedBy, // quién lo pidió (opcional)
  }) =>
      _writer.undoable([ // guarda con tiempo para deshacer
        PendingEvent(
          RequestAddedEvent( // la solicitud
            description: description, // descripción
            origin: RequestOrigin.cannotDoNow, // se creó con el botón "Solicitud después"
            requestedByText: requestedBy, // quién la pidió (texto escrito a mano)
          ),
          visitId: visitId, // visita
        ),
      ]);
}