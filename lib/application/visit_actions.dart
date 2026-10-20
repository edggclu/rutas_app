import '../data/local/outbox_repository.dart'; // la cola
import '../data/location_service.dart'; // la ubicación
import '../domain/closing.dart'; // WarrantyCause, BlockReason, IncidentKind, MaterialUsed
import '../domain/extras.dart'; // ExtraDraft
import '../domain/models.dart'; // Visit y ChecklistItem
import 'action_receipt.dart'; // el comprobante
import 'arrival_actions.dart'; // área: llegada
import 'closing_actions.dart'; // área: cierre
import 'departure_actions.dart'; // área: salida
import 'extras_actions.dart'; // área: extras
import 'no_answer_actions.dart'; // área: "No me abren"
import 'outbox_writer.dart'; // el ayudante que escribe en la cola

export 'action_receipt.dart'; // quien importe este archivo también ve ActionReceipt
export 'extras_actions.dart' show ExtraResult; // ...y ExtraResult

/// FACHADA TEMPORAL. Mantiene los mismos métodos que antes para que las pantallas
/// y los tests no cambien. Cada método solo delega en su área. En el paso B las
/// pantallas usarán las áreas directamente (`actions.arrival.arrive(...)`) y esta
/// lista de delegados se borra.
class VisitActions { // el punto único que usan hoy las pantallas
  VisitActions( // constructor (la misma firma que tenía antes)
    OutboxRepository outbox, // la cola
    Future<int> Function() graceSeconds, // cómo leer los segundos para deshacer
    LocationService location, // la ubicación
  )   : _writer = OutboxWriter(outbox, graceSeconds), // crea el ayudante una sola vez
        _location = location; // guarda la ubicación para el área de llegada

  final OutboxWriter _writer; // el ayudante compartido
  final LocationService _location; // la ubicación

  // Las áreas. `late final` = se crean la primera vez que se usan.
  late final DepartureActions departure = DepartureActions(_writer); // salida
  late final ArrivalActions arrival = ArrivalActions(_writer, _location); // llegada
  late final NoAnswerActions noAnswer = NoAnswerActions(_writer); // "No me abren"
  late final ExtrasActions extras = ExtrasActions(_writer); // extras y solicitudes
  late final ClosingActions closing = ClosingActions(_writer); // cierre

  // ---- Delegados: mismos nombres y parámetros que antes ----
  Future<ActionReceipt> confirmDeparture({ // salida
    required List<Visit> visits,
    required Map<int, List<ChecklistItem>> missing,
  }) =>
      departure.confirmDeparture(visits: visits, missing: missing); // delega en el área

  Future<ActionReceipt> arrive({required int visitId}) => // llegada
      arrival.arrive(visitId: visitId); // delega en el área

  Future<void> reportNoAnswer({required int visitId}) => // "No me abren"
      noAnswer.reportNoAnswer(visitId: visitId); // delega en el área

  Future<void> registerClientContact({required int visitId, required String channel}) => // contacto con el cliente
      noAnswer.registerClientContact(visitId: visitId, channel: channel); // delega en el área

  Future<void> registerOfficeCall({required int visitId}) => // llamada a la oficina
      noAnswer.registerOfficeCall(visitId: visitId); // delega en el área

  Future<ActionReceipt> confirmNoAnswer({required int visitId}) => // "No me atendieron"
      noAnswer.confirmNoAnswer(visitId: visitId); // delega en el área

  Future<ExtraResult> addExtra({required Visit visit, required ExtraDraft draft}) => // extra
      extras.addExtra(visit: visit, draft: draft); // delega en el área

  Future<ActionReceipt> addRequest({ // solicitud para después
    required int visitId,
    required String description,
    String? requestedBy,
  }) =>
      extras.addRequest(visitId: visitId, description: description, requestedBy: requestedBy); // delega en el área

  Future<ActionReceipt> finish({ // "Terminé el trabajo"
    required int visitId,
    String? confirmedBy,
    String? confirmedRole,
  }) =>
      closing.finish(visitId: visitId, confirmedBy: confirmedBy, confirmedRole: confirmedRole); // delega en el área

  Future<ActionReceipt> documentWarranty({ // garantía
    required int visitId,
    required WarrantyCause cause,
    String? serial,
  }) =>
      closing.documentWarranty(visitId: visitId, cause: cause, serial: serial); // delega en el área

  Future<ActionReceipt> continueTomorrow({ // "Sigo otro día"
    required int visitId,
    required List<MaterialUsed> materials,
    required String leftOnSite,
    required String missing,
    required bool laidCable,
  }) =>
      closing.continueTomorrow( // delega en el área
        visitId: visitId,
        materials: materials,
        leftOnSite: leftOnSite,
        missing: missing,
        laidCable: laidCable,
      );

  Future<ActionReceipt> blockVisit({ // "No pude seguir"
    required int visitId,
    required BlockReason reason,
    IncidentKind? incidentKind,
    required String note,
  }) =>
      closing.blockVisit(visitId: visitId, reason: reason, incidentKind: incidentKind, note: note); // delega en el área

  Future<void> requestHelp({required int visitId}) => // pedir ayuda al ingeniero
      closing.requestHelp(visitId: visitId); // delega en el área

  Future<void> undo(ActionReceipt receipt) => _writer.undo(receipt); // deshacer cualquier acción
}