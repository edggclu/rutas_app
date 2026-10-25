import 'package:telyser_app/domain/models/event_models.dart';

import '../data/location_service.dart';
import '../domain/events/event_data.dart';
import 'action_receipt.dart';
import 'outbox_writer.dart';

/// Acciones de la llegada.
class ArrivalActions { // una clase por área
  ArrivalActions(this._writer, this._location); // recibe el ayudante y la ubicación

  final OutboxWriter _writer; // escribe en la cola
  final LocationService _location; // quien sabe dar la ubicación (real o falsa en tests)

  /// "Llegué" manual: guarda la llegada con la hora y la ubicación del momento.
  Future<ActionReceipt> arrive({required int visitId}) async { // visitId = a qué visita llegó
    final point = await _location.currentPosition(); // lee el GPS (puede ser null si no se pudo)
    return _writer.undoable([ // guarda la llegada con tiempo para deshacer
      PendingEvent(
        ArrivedEvent(mode: ArrivalMode.manual, lat: point?.lat, lng: point?.lng), // modo y ubicación (null si no hubo GPS)
        visitId: visitId, // en qué visita
      ),
    ]);
  }
}