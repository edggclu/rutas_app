import '../domain/closing.dart'; // WarrantyCause, BlockReason, IncidentKind, MaterialUsed
import '../domain/event_types.dart'; // nombres de los eventos
import 'action_receipt.dart'; // el comprobante
import 'outbox_writer.dart'; // el ayudante que escribe en la cola

/// Acciones de cierre: terminar, garantía, "sigo otro día" y "no pude seguir".
class ClosingActions { // una clase por área
  ClosingActions(this._writer); // recibe el ayudante

  final OutboxWriter _writer; // escribe en la cola

  /// Deslizable "Terminé el trabajo". Si hubo extras, lleva quién los confirmó.
  Future<ActionReceipt> finish({ // devuelve el comprobante para deshacer
    required int visitId, // visita que se cierra
    String? confirmedBy, // nombre del contacto que confirmó los extras
    String? confirmedRole, // su cargo (opcional)
  }) =>
      _writer.undoable([ // es deslizable: con deshacer
        PendingEvent(
          EventTypes.finished, // tipo: "terminé el trabajo"
          visitId: visitId, // visita
          payload: { // datos extra (vacío si no hubo extras)
            if (confirmedBy != null) 'extras_confirmed_by': confirmedBy, // quién confirmó
            if (confirmedRole != null && confirmedRole.isNotEmpty) 'extras_confirmed_role': confirmedRole, // su cargo
          },
        ),
      ]);

  /// Guarda el bloque de garantía: causa y número de serie (las fotos van aparte, en media_queue).
  Future<ActionReceipt> documentWarranty({ // devuelve el comprobante
    required int visitId, // visita
    required WarrantyCause cause, // causa elegida
    String? serial, // número de serie escrito (null si solo fotografió la etiqueta)
  }) =>
      _writer.undoable([ // con tiempo para deshacer
        PendingEvent(
          EventTypes.warrantyDocumented, // tipo: garantía documentada
          visitId: visitId, // visita
          payload: {'cause': cause.code, 'serial': serial}, // causa y serial
        ),
      ]);

  /// "Sigo otro día": cierra la visita sin terminar el trabajo.
  Future<ActionReceipt> continueTomorrow({ // devuelve el comprobante
    required int visitId, // visita
    required List<MaterialUsed> materials, // material usado hoy
    required String leftOnSite, // qué se queda en el sitio
    required String missing, // qué falta por hacer
    required bool laidCable, // ¿se tendió cable hoy?
  }) =>
      _writer.undoable([ // con tiempo para deshacer
        PendingEvent(
          EventTypes.continueTomorrow, // tipo: sigo otro día
          visitId: visitId, // visita
          payload: { // datos para quien continúe el trabajo
            'materials_used': [for (final m in materials) m.toJson()], // material usado
            'left_on_site': leftOnSite.trim(), // lo que se queda
            'missing': missing.trim(), // lo que falta
            'laid_cable': laidCable, // si tendió cable
          },
        ),
      ]);

  /// "No pude seguir": algo detiene el trabajo y alguien debe resolverlo.
  Future<ActionReceipt> blockVisit({ // devuelve el comprobante
    required int visitId, // visita
    required BlockReason reason, // motivo (el servidor decide a quién avisar)
    IncidentKind? incidentKind, // subtipo, solo si el motivo es incidente
    required String note, // nota escrita
  }) =>
      _writer.undoable([ // con tiempo para deshacer
        PendingEvent(
          EventTypes.blocked, // tipo: no pude seguir
          visitId: visitId, // visita
          payload: { // datos
            'reason': reason.code, // motivo
            'incident_kind': incidentKind?.code, // subtipo (null si no aplica)
            'note': note.trim(), // nota
          },
        ),
      ]);

  /// Toque en "Pedir ayuda al ingeniero" (el WhatsApp se abre desde la pantalla).
  Future<void> requestHelp({required int visitId}) => // visita donde pide ayuda
      _writer.instant(PendingEvent(EventTypes.helpRequested, visitId: visitId)); // botón normal: sin deshacer
}