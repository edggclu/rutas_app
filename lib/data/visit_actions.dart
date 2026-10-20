import 'package:telyser_app/data/local/outbox_repository.dart';
import 'package:telyser_app/data/location_service.dart';
import 'package:telyser_app/domain/closing.dart';
import 'package:telyser_app/domain/enums.dart';
import 'package:telyser_app/domain/event_types.dart';
import 'package:telyser_app/domain/extras.dart';
import 'package:telyser_app/domain/models.dart';

/// Comprobante de lo que se encolo, sirve para deshacerlo
class ActionReceipt {

  /// Identificadores de las filas creadas en la cola
  final List<String> uuids;

  /// Segundos que dura el tiempo para deshacer (parametro: 'undo_seconds')
  final int graceSeconds;
  
  const ActionReceipt(this.uuids, this.graceSeconds);
}

/// Resultado de guardar un extra: qué decidió la app y el comprobante para deshacer.
class ExtraResult { // lo que devuelve addExtra
  const ExtraResult(this.outcome, this.receipt); 
  final ExtraOutcome outcome; // que se decidió / se hizo, o quedo como solicitud
  final ActionReceipt receipt; // para poder deshacer
}

/// Acciones del tecnico. Cada metodo guarda eventos en la cola (en estado 'grace') y devuelve un comprobante.
/// Esta clase decide que eventos se encolan por cada accion
class VisitActions {
  final OutboxRepository _outbox; // la cola donde se guarda todo
  final Future<int> Function() _graceSeconds; // función que lee `undo_seconds` de los parámetros
  final LocationService _location; // quien sabe dar la ubicacion real o falsa en tests

  VisitActions(this._outbox, this._graceSeconds, this._location);

  // Levo todo o Salir con faltantes
  Future<ActionReceipt> confirmDeparture({ // encola los eventos de la salida
    required List<Visit> visits,
    required Map<int, List<ChecklistItem>> missing, // id de visita : item que falta
  }) async {
    final grace = await _graceSeconds(); // lee los segundos
    final first = visits.firstWhere((v) => v.status == VisitStatus.pending); // primera visita por hacer
    final uuids = <String>[];

    // recorre cada visita que tiene faltantes
    for (final entry in missing.entries) {
      uuids.add(await _outbox.enqueue(
        type: EventTypes.missingItems, 
        graceSeconds: grace,
        visitId: entry.key, // de que visita es
        payload: {
          'items': [
            for (final i in entry.value) // cada item faltante
            {'id': i.id, 'text': i.text, 'kind': i.kind.name},
          ]
        }
      ));
    }

    // Encola la salida, siempre va después de los faltantes
    uuids.add(await _outbox.enqueue(
      type: EventTypes.departureConfirmed, // salida confirmada
      graceSeconds: grace,
      visitId: first.id
    ));

    // devuelve el comprobante
    return ActionReceipt(uuids, grace);
  }

    /// "Llegué" manual: guarda la llegada con la hora y la ubicación del momento.
  Future<ActionReceipt> arrive({required int visitId}) async {
    final grace = await _graceSeconds(); // lee los segundos para deshacer
    final point = await _location.currentPosition(); // lee el GPS (puede ser null si no se pudo)
    final uuid = await _outbox.enqueue( // guarda la acción en la cola
      type: EventTypes.arrived,
      graceSeconds: grace,
      visitId: visitId,
      payload: { // los datos que viajarán al servidor
        'mode':'manual', // el tipo de arrive, si se desliza es manual, el automatico es auto
        'lat': point?.lat, // ? por si regresa nulo
        'lng':point?.lng
      }
    ); 
    return ActionReceipt([uuid], grace); // comprobante con una sola fila
  }

  /// Toque en "No me abren": avisa a la oficina. Solo se avisa una vez por visita.
  Future<void> reportNoAnswer({required int visitId}) async {
    final already = await _outbox.exists(type: EventTypes.noAnswerReported, visitId: visitId); // revisa que no exista un reporte
    if (already) return;

    // guarda el aviso en la cola
    await _outbox.enqueue(
      type: EventTypes.noAnswerReported, 
      graceSeconds: 0,
      visitId: visitId);
  }
  
  /// Toque en llamar o whatsApp al cliente. [channel] es 'call' o 'whatsapp'.
  Future<void> registerClientContact ({
    required int visitId,
    required String channel,
  }) async {
    // guarda el intento en la cola
    await _outbox.enqueue(type: EventTypes.clientContacted, graceSeconds: 0,
      visitId: visitId,
      payload: {'channel':channel}
    );
  }

  /// Toque en 'Llamar a la oficina'
  Future<void> registerOfficeCall({required int visitId}) async {
    // guarda el intento en la cola
    await _outbox.enqueue( 
      type: EventTypes.officeCalled, // tipo: "llamé a la oficina"
      graceSeconds: 0,
      visitId: visitId,
    );
  }

  /// Deslizable "No me atendieron": cierra la visita con ese resultado.
  Future<ActionReceipt> confirmNoAnswer({required int visitId}) async {
    final grace = await _graceSeconds();
    final uuid = await _outbox.enqueue(
      type: EventTypes.noAnswerConfirmed, graceSeconds: grace,
      visitId: visitId);
    return ActionReceipt([uuid], grace); // comprobante para poder deshacer
  }

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
    final grace = await _graceSeconds(); // segundos para deshacer (parámetro del servidor)
    final outcome = decideExtra( // aplica las reglas
      requestedByAuthorized: draft.requestedByAuthorized, // ¿lo pidió el contacto autorizado?
      clientOverdue: visit.client.overdue, // ¿el cliente tiene saldo vencido?
      isEquipment: draft.isEquipment, // ¿es equipo?
      notInstalled: draft.notInstalled, // ¿es "no se instaló"?
    );
    final uuids = <String>[]; // ids de las filas que se creen

    if (outcome == ExtraOutcome.register) { // se hace y se anota
      uuids.add(await _outbox.enqueue( // guarda el extra en la cola
        type: EventTypes.extraAdded, // tipo: extra
        graceSeconds: grace, // con tiempo para deshacer
        visitId: visit.id, // visita
        payload: _extraPayload(draft, visit), // datos del extra
      ));
      final minutes = draft.delayMinutes; // retraso estimado
      if (minutes != null && minutes > 0) { // si va a retrasar las siguientes visitas
        uuids.add(await _outbox.enqueue( // avisa al jefe
          type: EventTypes.routeDelayReported, // tipo: retraso de ruta
          graceSeconds: grace, // con tiempo para deshacer
          visitId: visit.id, // visita
          payload: {'minutes': minutes, 'reason': 'extra', 'extra_name': draft.name}, // cuánto y por qué
        ));
      }
    } else { // no se hace: queda como solicitud para después
      uuids.add(await _outbox.enqueue( // guarda la solicitud en la cola
        type: EventTypes.requestAdded, // tipo: solicitud
        graceSeconds: grace, // con tiempo para deshacer
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
    return ExtraResult(outcome, ActionReceipt(uuids, grace)); // devuelve qué pasó y cómo deshacerlo
  }

  /// Guarda una solicitud para después (lo que no se puede hacer en esta visita).
  Future<ActionReceipt> addRequest({ // devuelve el comprobante para deshacer
    required int visitId, // visita
    required String description, // qué pidió el cliente
    String? requestedBy, // quién lo pidió (opcional)
  }) async {
    final grace = await _graceSeconds(); // segundos para deshacer
    final uuid = await _outbox.enqueue( // guarda la solicitud en la cola
      type: EventTypes.requestAdded, // tipo: solicitud
      graceSeconds: grace, // con tiempo para deshacer
      visitId: visitId, // visita
      payload: { // datos
        'description': description, // descripción
        'requested_by': requestedBy, // quién la pidió
        'origin': 'cannot_do_now', // se creó con el botón "Solicitud después"
      },
    );
    return ActionReceipt([uuid], grace); // comprobante
  }

    /// Guarda el bloque de garantía: causa y número de serie (las fotos van aparte, en media_queue).
  Future<ActionReceipt> documentWarranty({ // devuelve el comprobante
    required int visitId, // visita
    required WarrantyCause cause, // causa elegida
    String? serial, // número de serie escrito (null si solo fotografió la etiqueta)
  }) async {
    final grace = await _graceSeconds(); // segundos para deshacer
    final uuid = await _outbox.enqueue( // guarda en la cola
      type: EventTypes.warrantyDocumented, // tipo: garantía documentada
      graceSeconds: grace, // con tiempo para deshacer
      visitId: visitId, // visita
      payload: {'cause': cause.code, 'serial': serial}, // causa y serial
    );
    return ActionReceipt([uuid], grace); // comprobante
  }

  /// "Sigo otro día": cierra la visita sin terminar el trabajo.
  Future<ActionReceipt> continueTomorrow({ // devuelve el comprobante
    required int visitId, // visita
    required List<MaterialUsed> materials, // material usado hoy
    required String leftOnSite, // qué se queda en el sitio
    required String missing, // qué falta por hacer
    required bool laidCable, // ¿se tendió cable hoy?
  }) async {
    final grace = await _graceSeconds(); // segundos para deshacer
    final uuid = await _outbox.enqueue( // guarda en la cola
      type: EventTypes.continueTomorrow, // tipo: sigo otro día
      graceSeconds: grace, // con tiempo para deshacer
      visitId: visitId, // visita
      payload: { // datos para quien continúe el trabajo
        'materials_used': [for (final m in materials) m.toJson()], // material usado
        'left_on_site': leftOnSite.trim(), // lo que se queda
        'missing': missing.trim(), // lo que falta
        'laid_cable': laidCable, // si tendió cable
      },
    );
    return ActionReceipt([uuid], grace); // comprobante
  }

  /// "No pude seguir": algo detiene el trabajo y alguien debe resolverlo.
  Future<ActionReceipt> blockVisit({ // devuelve el comprobante
    required int visitId, // visita
    required BlockReason reason, // motivo (el servidor decide a quién avisar)
    IncidentKind? incidentKind, // subtipo, solo si el motivo es incidente
    required String note, // nota escrita
  }) async {
    final grace = await _graceSeconds(); // segundos para deshacer
    final uuid = await _outbox.enqueue( // guarda en la cola
      type: EventTypes.blocked, // tipo: no pude seguir
      graceSeconds: grace, // con tiempo para deshacer
      visitId: visitId, // visita
      payload: { // datos
        'reason': reason.code, // motivo
        'incident_kind': incidentKind?.code, // subtipo (null si no aplica)
        'note': note.trim(), // nota
      },
    );
    return ActionReceipt([uuid], grace); // comprobante
  }

  /// Toque en "Pedir ayuda al ingeniero" (el WhatsApp se abre desde la pantalla).
  Future<void> requestHelp({required int visitId}) async { // visita donde pide ayuda
    await _outbox.enqueue( // guarda el aviso en la cola
      type: EventTypes.helpRequested, // tipo: pidió ayuda
      graceSeconds: 0, // botón normal: sin deshacer
      visitId: visitId, // visita
    );
  }

  /// Deshace todo lo que contiene el comprobante.
  Future<void> undo(ActionReceipt receipt) async { // recibe el comprobante de la acción
    for (final id in receipt.uuids) { // recorre cada fila creada
      await _outbox.undo(id); // la borra solo si sigue dentro de los segundos de gracia
    }
  }

    /// Deslizable "Terminé el trabajo". Si hubo extras, lleva quién los confirmó.
  Future<ActionReceipt> finish({ // devuelve el comprobante para deshacer
    required int visitId, // visita que se cierra
    String? confirmedBy, // nombre del contacto que confirmó los extras
    String? confirmedRole, // su cargo (opcional)
  }) async {
    final grace = await _graceSeconds(); // segundos para deshacer
    final uuid = await _outbox.enqueue( // guarda el cierre en la cola
      type: EventTypes.finished, // tipo: "terminé el trabajo"
      graceSeconds: grace, // es deslizable: lleva tiempo para deshacer
      visitId: visitId, // visita
      payload: { // datos extra (vacío si no hubo extras)
        if (confirmedBy != null) 'extras_confirmed_by': confirmedBy, // quién confirmó
        if (confirmedRole != null && confirmedRole.isNotEmpty) 'extras_confirmed_role': confirmedRole, // su cargo
      },
    );
    return ActionReceipt([uuid], grace); // comprobante para poder deshacer
  }

}

