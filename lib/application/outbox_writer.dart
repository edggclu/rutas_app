import '../data/local/outbox_repository.dart'; // la cola
import 'action_receipt.dart'; // el comprobante

/// Un evento por guardar: lo que una acción del técnico quiere escribir en la cola.
class PendingEvent { // solo agrupa los datos de un evento
  const PendingEvent( // constructor
    this.type, { // tipo de evento (arrived, finished...)
    this.visitId, // visita a la que pertenece
    this.payload = const {}, // datos extra
  });

  final String type; // tipo
  final int? visitId; // visita
  final Map<String, dynamic> payload; // datos extra
}

/// Escribe en la cola. Aquí vive, una sola vez, lo que antes se repetía en cada acción.
class OutboxWriter { // el ayudante de todas las áreas
  OutboxWriter(this._outbox, this._graceSeconds); // recibe la cola y cómo leer los segundos de gracia

  final OutboxRepository _outbox; // la cola
  final Future<int> Function() _graceSeconds; // lee `undo_seconds` de los parámetros

  /// Guarda uno o varios eventos CON tiempo para deshacer (acciones deslizables y formularios).
  /// Todos comparten el mismo comprobante, así que un solo "Deshacer" borra todos.
  Future<ActionReceipt> undoable(List<PendingEvent> events) async { // devuelve el comprobante
    final grace = await _graceSeconds(); // segundos para deshacer, de los parámetros
    final uuids = <String>[]; // aquí se juntan los ids de las filas creadas
    for (final e in events) { // en el orden en que se pidieron
      uuids.add(await _outbox.enqueue( // guarda el evento y recuerda su id
        type: e.type, // tipo
        graceSeconds: grace, // con tiempo para deshacer
        visitId: e.visitId, // visita
        payload: e.payload, // datos extra
      ));
    }
    return ActionReceipt(uuids, grace); // el comprobante con todos los ids
  }

  /// Guarda un evento SIN tiempo para deshacer (botones normales: llamar, avisar...).
  Future<void> instant(PendingEvent e) async { // no devuelve comprobante
    await _outbox.enqueue( // guarda el evento
      type: e.type, // tipo
      graceSeconds: 0, // sin tiempo para deshacer
      visitId: e.visitId, // visita
      payload: e.payload, // datos extra
    );
  }

  /// ¿Ya existe un evento de este tipo para esta visita? (para no avisar dos veces)
  Future<bool> exists({required String type, required int visitId}) => // true si ya existe
      _outbox.exists(type: type, visitId: visitId); // lo pregunta a la cola

  /// Deshace todo lo que contiene el comprobante (solo lo que siga en gracia).
  Future<void> undo(ActionReceipt receipt) async { // recibe el comprobante
    for (final id in receipt.uuids) { // por cada fila creada
      await _outbox.undo(id); // la borra si sigue dentro de los segundos de gracia
    }
  }
}