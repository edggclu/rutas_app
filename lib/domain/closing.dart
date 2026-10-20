import 'package:telyser_app/domain/event_types.dart';
import 'package:telyser_app/domain/visit_state.dart';

/// Causa de la falla en una visita de garantía.
enum WarrantyCause { // opciones del bloque de garantía
  defect('defect', 'Defecto'), // defecto de fábrica
  humiditySalt('humidity_salt', 'Humedad o salitre'), // el ambiente de la costa
  impact('impact', 'Golpe'), // daño físico
  powerSurge('power_surge', 'Variación eléctrica'), // picos o caídas de voltaje
  tampering('tampering', 'Manipulación'), // alguien lo movió o lo abrió
  unknown('unknown', 'No se sabe'); // el ingeniero lo dictamina después con las fotos

  const WarrantyCause(this.code, this.label); // constructor de cada opción
  final String code; // texto que viaja al servidor
  final String label; // texto que ve el técnico

  /// Causas claramente externas: probablemente se cobre al cliente, así que el
  /// técnico debe llamar a la oficina ANTES de reparar. (Lista provisional.)
  bool get isExternal => this == impact || this == tampering; // golpe o manipulación
}

/// Motivo de "No pude seguir". El servidor decide a quién avisar según el código.
enum BlockReason { // los seis motivos del documento
  missingMaterial('missing_material', 'Falta material o herramienta', 'Se avisa a Axel y al jefe'), // incluye equipo defectuoso
  siteDiffers('site_differs', 'El sitio no es como el plan', 'Se avisa al ingeniero a cargo'), // ej. no hay corriente
  cannotSolve('cannot_solve', 'No puedo resolverlo', 'Se avisa al jefe, al ingeniero y a administración'), // requiere segunda visita
  client('client', 'Cliente: pago, garantía o inconformidad', 'Se avisa a administración'), // problema con el cliente
  incident('incident', 'Incidente: seguridad, daño o accidente', 'Se avisa a administración'), // algo grave
  other('other', 'Otro', 'Se avisa al jefe'); // cualquier otro caso

  const BlockReason(this.code, this.label, this.notifies); // constructor de cada opción
  final String code; // texto que viaja al servidor
  final String label; // texto de la tarjeta
  final String notifies; // a quién se avisa (solo ayuda visual para el técnico)
}

/// Subtipo cuando el motivo es un incidente.
enum IncidentKind { // cada uno exige algo distinto
  safety('safety', 'Seguridad'), // un riesgo
  propertyDamage('property_damage', 'Daño a la propiedad'), // ej. rompí un azulejo: exige fotos
  accident('accident', 'Accidente'); // alguien se lastimó: primero se pide ayuda

  const IncidentKind(this.code, this.label); // constructor de cada opción
  final String code; // texto que viaja al servidor
  final String label; // texto que ve el técnico
}

/// Un renglón de material usado en "Sigo otro día".
class MaterialUsed { // lo planeado contra lo realmente usado
  const MaterialUsed({ // constructor
    required this.id, // id del renglón de la lista de salida
    required this.text, // nombre del material
    required this.planned, // cantidad planeada
    required this.used, // cantidad usada hoy
  });

  final int id; // id del renglón
  final String text; // nombre
  final num planned; // planeado
  final num used; // usado

  Map<String, dynamic> toJson() => // datos tal como viajan al servidor
      {'id': id, 'text': text, 'planned': planned, 'used': used}; // las cuatro llaves
}

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
    events.any((e) => e.visitId == visitId && e.type == EventTypes.warrantyDocumented); // busca ese tipo en esta visita

/// Última causa documentada, para mostrarla en el resumen. null si no hay.
WarrantyCause? lastWarrantyCause(List<VisitEvent> events, int visitId) {
  for (final e in events.reversed) { 
    if (e.visitId == visitId && e.type == EventTypes.warrantyDocumented) { // la primera que coincida es la última guardada
      for (final c in WarrantyCause.values) { // busca la causa por su código
        if (c.code == e.payload['cause']) return c; 
      }
      return null; 
    }
  }
  return null; 
}