import 'payload.dart';

/// Tipo de foto o video.
enum MediaKind { // los tipos que existen
  progress('progress'), // avance del trabajo
  warranty('warranty'), // foto de la falla en una garantía
  warrantySerial('warranty_serial'), // foto de la etiqueta con el número de serie
  damage('damage'), // daño a la propiedad o incidente
  request('request'), // foto de una solicitud para después
  cablingVideo('cabling_video'); // video del cableado antes de cerrar el plafón

  const MediaKind(this.code); // constructor de cada opción
  final String code; // texto que se guarda en la base y viaja al servidor
  static MediaKind? tryFromCode(String? c) => lookup(values, c, (v) => v.code); // null si no existe
  bool get isVideo => this == MediaKind.cablingVideo; // los demás tipos son fotos
}

/// Una foto o video de una visita, tal como lo necesitan las pantallas.
class MediaItem { // sin nada de Drift
  const MediaItem({ // constructor
    required this.id, // identificador único
    required this.kind, // tipo
    required this.localPath, // dónde está guardado en el teléfono
    required this.sent, // ¿ya se subió al servidor?
  });

  final String id; // identificador único
  final MediaKind kind; // tipo
  final String localPath; // ruta del archivo en el teléfono
  final bool sent; // true = ya se subió
}