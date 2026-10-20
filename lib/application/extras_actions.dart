import '../domain/event_types.dart'; // nombres de los eventos
import '../domain/extras.dart'; // ExtraDraft, ExtraOutcome, decideExtra, quantityText
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

  /// Datos del extra tal como viajan al servidor (llaves en snake_case, como el contrato).
  Map<String, dynamic> _extraPayload(ExtraDraft d, Visit visit) => { // arma el mapa de datos
        'name': d.name, // nombre
        'product_id': d.productId, // id del catálogo (null si lo escribió)
        'quantity': d.quantity, // cantidad
        'unit': d.unit, // unidad
        'source': d.source.code, // de dónde salió
        'reason': d.reason.code, // por qué
        'requested_by': d.requestedByAuthorized ? 'authorized_contact' : 'other', // quién lo pidió
        'requester_name': d.requestedByAuthorized ? visit.place.contact?.name : null, // nombre del contacto, si fue él
        'not_installed': d.notInstalled, // ¿es "no se instaló"?
      };

  /// Guarda un extra aplicando las reglas del negocio.
  Future<ExtraResult> addExtra({required Visit visit, required ExtraDraft draft}) async { // visita y formulario llenado
    final outcome = decideExtra( // aplica las reglas
      requestedByAuthorized: draft.requestedByAuthorized, // ¿lo pidió el contacto autorizado?
      clientOverdue: visit.client.overdue, // ¿el cliente tiene saldo vencido?
      isEquipment: draft.isEquipment, // ¿es equipo?
      notInstalled: draft.notInstalled, // ¿es "no se instaló"?
    );
    final events = <PendingEvent>[]; // los eventos que habrá que guardar

    if (outcome == ExtraOutcome.register) { // se hace y se anota
      events.add(PendingEvent( // el extra
        EventTypes.extraAdded, // tipo: extra
        visitId: visit.id, // visita
        payload: _extraPayload(draft, visit), // datos del extra
      ));
      final minutes = draft.delayMinutes; // retraso estimado
      if (minutes != null && minutes > 0) { // si va a retrasar las siguientes visitas
        events.add(PendingEvent( // aviso al jefe
          EventTypes.routeDelayReported, // tipo: retraso de ruta
          visitId: visit.id, // visita
          payload: {'minutes': minutes, 'reason': 'extra', 'extra_name': draft.name}, // cuánto y por qué
        ));
      }
    } else { // no se hace: queda como solicitud para después
      events.add(PendingEvent( // la solicitud
        EventTypes.requestAdded, // tipo: solicitud
        visitId: visit.id, // visita
        payload: { // datos de la solicitud
          ..._extraPayload(draft, visit), // los mismos datos del extra
          'description': '${quantityText(draft.quantity)} × ${draft.name}', // texto para administración
          'origin': outcome == ExtraOutcome.laterOtherPerson // por qué quedó como solicitud
              ? 'other_person' // la pidió otra persona
              : 'credit_hold', // el cliente tiene saldo vencido
        },
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
          EventTypes.requestAdded, // tipo: solicitud
          visitId: visitId, // visita
          payload: { // datos
            'description': description, // descripción
            'requested_by': requestedBy, // quién la pidió
            'origin': 'cannot_do_now', // se creó con el botón "Solicitud después"
          },
        ),
      ]);
}