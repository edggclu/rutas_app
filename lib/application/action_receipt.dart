/// Comprobante de lo que se encoló: sirve para deshacerlo.
class ActionReceipt { // lo que devuelve cada acción del técnico
  const ActionReceipt(this.uuids, this.graceSeconds); // constructor: recibe los ids y los segundos

  /// Identificadores de las filas creadas en la cola.
  final List<String> uuids; // los ids de las filas que se guardaron

  /// Segundos que dura el tiempo para deshacer (parámetro `undo_seconds`).
  final int graceSeconds; // cuánto dura el "Deshacer"
}