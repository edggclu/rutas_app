import 'events/event_data.dart'; // WarrantyDocumentedEvent
import 'models/closing_models.dart'; // WarrantyCause, BlockReason, IncidentKind
import 'visit_state.dart'; // VisitEvent

export 'models/closing_models.dart'; // quien importe closing.dart sigue viendo los tipos de cierre

/// Bloque de garantía: causa elegida, al menos una foto de la falla y el número
/// de serie (escrito o en foto de la etiqueta).
bool canSaveWarranty({
  required WarrantyCause? cause, // causa elegida (null = ninguna)
  required int failurePhotos, // fotos de la falla
  required String serial, // número de serie escrito
  required int serialPhotos, // fotos de la etiqueta
}) =>
    cause != null && // eligió una causa
    failurePhotos > 0 && // tomó al menos una foto de la falla
    (serial.trim().isNotEmpty || serialPhotos > 0); // escribió el serial o fotografió la etiqueta

/// "Sigo otro día": lo que falta es obligatorio; si tendió cable, también el video.
bool canContinueTomorrow({
  required String missing, // qué falta por hacer
  required bool laidCable, // ¿hoy se tendió cable?
  required int cablingVideos, // videos del cableado grabados
}) =>
    missing.trim().isNotEmpty && // escribió qué falta
    (!laidCable || cablingVideos > 0); // si tendió cable, grabó el video

/// "No pude seguir": motivo y nota; los incidentes piden más.
bool canSendBlocked({
  required BlockReason? reason, // motivo elegido
  required IncidentKind? incidentKind, // subtipo (solo si es incidente)
  required String note, // nota escrita
  required int damagePhotos, // fotos del daño
}) {
  if (reason == null) return false; // sin motivo no se envía
  if (note.trim().isEmpty) return false; // la nota es obligatoria
  if (reason == BlockReason.incident) { // si es un incidente
    if (incidentKind == null) return false; // debe elegir de qué tipo
    if (incidentKind == IncidentKind.propertyDamage && damagePhotos == 0) return false; // daño: exige fotos
  }
  return true; // todo en orden
}

/// ¿Ya se documentó la garantía de esta visita? (se lee de la cola)
bool warrantyDocumented(List<VisitEvent> events, int visitId) => // true si existe el evento
    events.any((e) => e.visitId == visitId && e.data is WarrantyDocumentedEvent); // busca esa clase en esta visita

/// Última causa documentada, para mostrarla en el resumen. null si no hay.
WarrantyCause? lastWarrantyCause(List<VisitEvent> events, int visitId) {
  for (final e in events.reversed) { // de la acción más reciente a la más antigua
    final d = e.data; // el evento tipado
    if (e.visitId == visitId && d is WarrantyDocumentedEvent) return d.cause; // la primera que coincida es la última guardada
  }
  return null; // nunca se documentó
}