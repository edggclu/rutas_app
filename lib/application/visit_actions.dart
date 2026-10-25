import '../data/local/outbox_repository.dart';
import '../data/location_service.dart';
import 'action_receipt.dart';
import 'arrival_actions.dart';
import 'closing_actions.dart';
import 'departure_actions.dart';
import 'extras_actions.dart';
import 'no_answer_actions.dart';
import 'outbox_writer.dart';

export 'action_receipt.dart';
export 'extras_actions.dart' show ExtraResult;

/// Reúne las áreas de acciones del técnico. Ya no tiene métodos propios: cada
/// pantalla usa directamente el área que necesita (`actions.arrival.arrive(...)`).
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