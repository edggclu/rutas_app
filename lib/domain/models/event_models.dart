import 'package:telyser_app/domain/models/payload.dart';

import 'enums.dart';

/// Cómo se marcó la llegada.
enum ArrivalMode { // dos formas
  manual('manual'), // el técnico deslizó "Llegué"
  auto('auto'); // la geocerca la detectó (paso 7)

  const ArrivalMode(this.code); // constructor de cada opción
  final String code; // texto que viaja al servidor
  static ArrivalMode? tryFromCode(String? c) => lookup(values, c, (v) => v.code); // null si no existe
}

/// Por dónde intentó contactar al cliente.
enum ContactChannel { // dos formas
  call('call'), // llamada
  whatsapp('whatsapp'); // WhatsApp

  const ContactChannel(this.code); // constructor de cada opción
  final String code; // texto que viaja al servidor
  static ContactChannel? tryFromCode(String? c) => lookup(values, c, (v) => v.code); // null si no existe
}

/// Un renglón que le falta al técnico al salir.
class MissingItem { // dato de un renglón faltante
  const MissingItem({required this.id, required this.text, required this.kind}); // constructor
  final int id; // id del renglón de la lista de salida
  final String text; // nombre
  final ChecklistKind kind; // material o herramienta

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'kind': kind.name}; // tal como viaja al servidor

  factory MissingItem.fromJson(Map<String, dynamic> j) => MissingItem( // lo reconstruye desde el mapa guardado
        id: readInt(j, 'id') ?? 0, // id (0 si falta)
        text: readString(j, 'text') ?? '', // nombre (vacío si falta)
        kind: ChecklistKind.parse(readString(j, 'kind')), // tipo (material si falta)
      );
}