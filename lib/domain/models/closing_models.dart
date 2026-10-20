import 'payload.dart'; // lectores y lookup

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

  static WarrantyCause? tryFromCode(String? c) => lookup(values, c, (v) => v.code); // null si no existe
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

  static BlockReason? tryFromCode(String? c) => lookup(values, c, (v) => v.code); // null si no existe
}

/// Subtipo cuando el motivo es un incidente.
enum IncidentKind { // cada uno exige algo distinto
  safety('safety', 'Seguridad'), // un riesgo
  propertyDamage('property_damage', 'Daño a la propiedad'), // ej. rompí un azulejo: exige fotos
  accident('accident', 'Accidente'); // alguien se lastimó: primero se pide ayuda

  const IncidentKind(this.code, this.label); // constructor de cada opción
  final String code; // texto que viaja al servidor
  final String label; // texto que ve el técnico

  static IncidentKind? tryFromCode(String? c) => lookup(values, c, (v) => v.code); // null si no existe
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

  factory MaterialUsed.fromJson(Map<String, dynamic> j) => MaterialUsed( // lo reconstruye desde el mapa guardado
        id: readInt(j, 'id') ?? 0, // id (0 si falta)
        text: readString(j, 'text') ?? '', // nombre (vacío si falta)
        planned: readNum(j, 'planned') ?? 0, // planeado (0 si falta)
        used: readNum(j, 'used') ?? 0, // usado (0 si falta)
      );
}