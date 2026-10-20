import '../data/location_service.dart'; // para leer la ubicación
import '../domain/event_types.dart'; // nombres de los eventos
import 'action_receipt.dart'; // el comprobante
import 'outbox_writer.dart'; // el ayudante que escribe en la cola

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
        EventTypes.arrived, // tipo: "llegué"
        visitId: visitId, // en qué visita
        payload: { // los datos que viajarán al servidor
          'mode': 'manual', // se marcó deslizando (la automática será 'auto', paso 7)
          'lat': point?.lat, // latitud, o null si no hubo ubicación
          'lng': point?.lng, // longitud, o null si no hubo ubicación
        },
      ),
    ]);
  }
}