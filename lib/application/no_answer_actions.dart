import 'package:telyser_app/domain/models/event_models.dart';

import '../domain/event_types.dart'; // EventTypes: para preguntar si ya existe un aviso
import '../domain/events/event_data.dart'; // los eventos
import 'action_receipt.dart'; // el comprobante
import 'outbox_writer.dart'; // el ayudante que escribe en la cola

/// Acciones de "No me abren".
class NoAnswerActions { // una clase por área
  NoAnswerActions(this._writer); // recibe el ayudante

  final OutboxWriter _writer; // escribe en la cola

  /// Toque en "No me abren": avisa a la oficina. Solo se avisa una vez por visita.
  Future<void> reportNoAnswer({required int visitId}) async { // visitId = la visita donde nadie abrió
    final already = await _writer.exists( // ¿ya se avisó antes?
        type: EventTypes.noAnswerReported, visitId: visitId); // busca ese tipo para esa visita
    if (already) return; // ya se avisó: no se duplica
    await _writer.instant(PendingEvent(const NoAnswerReportedEvent(), visitId: visitId)); // botón normal: sin deshacer
  }

  /// Toque en llamar o WhatsApp al cliente.
  Future<void> registerClientContact({ // se registra el INTENTO (la app no sabe si la llamada entró)
    required int visitId, // visita
    required ContactChannel channel, // por dónde lo intentó
  }) =>
      _writer.instant(PendingEvent(ClientContactedEvent(channel), visitId: visitId)); // botón normal: sin deshacer

  /// Toque en "Llamar a la oficina".
  Future<void> registerOfficeCall({required int visitId}) => // visita donde está el técnico
      _writer.instant(PendingEvent(const OfficeCalledEvent(), visitId: visitId)); // botón normal: sin deshacer

  /// Deslizable "No me atendieron": cierra la visita con ese resultado.
  Future<ActionReceipt> confirmNoAnswer({required int visitId}) => // visita que se cierra
      _writer.undoable([PendingEvent(const NoAnswerConfirmedEvent(), visitId: visitId)]); // este sí es deslizable: con deshacer
}