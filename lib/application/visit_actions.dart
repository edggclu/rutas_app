import '../data/local/outbox_repository.dart'; // la cola
import '../data/location_service.dart'; // la ubicación
import 'action_receipt.dart'; // el comprobante
import 'arrival_actions.dart'; // área: llegada
import 'closing_actions.dart'; // área: cierre
import 'departure_actions.dart'; // área: salida
import 'extras_actions.dart'; // área: extras
import 'no_answer_actions.dart'; // área: "No me abren"
import 'outbox_writer.dart'; // el ayudante que escribe en la cola

export 'action_receipt.dart'; // quien importe este archivo también ve ActionReceipt
export 'extras_actions.dart' show ExtraResult; // ...y ExtraResult

/// Reúne las áreas de acciones del técnico. Ya no tiene métodos propios: cada
/// pantalla usa directamente el área que necesita (`actions.arrival.arrival.arrive(...)`).
class VisitActions { // el contenedor que crea el provider
  VisitActions( // constructor
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

  /// Deshace todo lo que contiene el comprobante (solo lo que siga en gracia).
  Future<void> undo(ActionReceipt receipt) => _writer.undo(receipt); // lo usa runUndoable
}