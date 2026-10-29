import '../domain/rules/closing.dart';
import '../domain/events/event_data.dart';
import '../domain/rules/visit_summary.dart'; // canAddNote
import 'action_receipt.dart';
import 'outbox_writer.dart';

/// Acciones de cierre: terminar, garantía, "sigo otro día" y "no pude seguir".
class ClosingActions { // una clase por área
  ClosingActions(this._writer); // recibe el ayudante

  final OutboxWriter _writer; // escribe en la cola

  /// Una nota en una visita ya cerrada, por si el técnico olvidó anotar algo. No cambia nada de
  /// lo guardado: solo agrega.
  Future<ActionReceipt> addNote({required int visitId, required String text}) {
    if (!canAddNote(text)) throw ArgumentError('La nota no puede ir vacía');
    return _writer.undoable([PendingEvent(NoteAddedEvent(text.trim()), visitId: visitId)]);
  }

  /// Deslizable "Terminé el trabajo". Si hubo extras, lleva quién los confirmó.
  Future<ActionReceipt> finish({ // devuelve el comprobante para deshacer
    required int visitId, // visita que se cierra
    String? confirmedBy, // nombre del contacto que confirmó los extras
    String? confirmedRole, // su cargo (opcional)
  }) =>
      _writer.undoable([ // es deslizable: con deshacer
        PendingEvent(
          FinishedEvent(confirmedBy: confirmedBy, confirmedRole: confirmedRole), // quién confirmó (si hubo extras)
          visitId: visitId, // visita
        ),
      ]);

  /// Guarda el bloque de garantía: causa y número de serie (las fotos van aparte, en media_queue).
  Future<ActionReceipt> documentWarranty({ // devuelve el comprobante
    required int visitId, // visita
    required WarrantyCause cause, // causa elegida
    String? serial, // número de serie escrito (null si solo fotografió la etiqueta)
  }) =>
      _writer.undoable([ // con tiempo para deshacer
        PendingEvent(WarrantyDocumentedEvent(cause: cause, serial: serial), visitId: visitId), // causa y serial
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
          ContinueTomorrowEvent( // los datos para quien continúe el trabajo
            materials: materials, // material usado
            leftOnSite: leftOnSite.trim(), // lo que se queda, sin espacios sobrantes
            missing: missing.trim(), // lo que falta, sin espacios sobrantes
            laidCable: laidCable, // si tendió cable
          ),
          visitId: visitId, // visita
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
          BlockedEvent(reason: reason, incidentKind: incidentKind, note: note.trim()), // motivo, subtipo y nota sin espacios sobrantes
          visitId: visitId, // visita
        ),
      ]);

  /// Toque en "Pedir ayuda al ingeniero" (el WhatsApp se abre desde la pantalla).
  Future<void> requestHelp({required int visitId}) => // visita donde pide ayuda
      _writer.instant(PendingEvent(const HelpRequestedEvent(), visitId: visitId)); // botón normal: sin deshacer
}