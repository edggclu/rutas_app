import 'package:telyser_app/domain/models/event_models.dart';

import 'event_types.dart'; // los nombres de los eventos, escritos en un solo lugar
import '../models/closing_models.dart'; // WarrantyCause, BlockReason, IncidentKind, MaterialUsed
import '../models/extra_models.dart'; // ExtraItem, RequestOrigin
import '../models/payload.dart'; // lectores de datos

/// Los datos de un evento de la cola. Hay una clase por tipo de evento.
/// `sealed` = todas las clases están en este archivo, así el compilador sabe
/// cuáles son y obliga a atenderlas todas en un `switch`.
sealed class EventData { // la clase base
  const EventData(); // constructor

  String get type; // el nombre del tipo (el de EventTypes)
  Map<String, dynamic> toPayload(); // los datos tal como se guardan y viajan al servidor

  /// Convierte un tipo y un mapa guardado en la clase correspondiente.
  /// NUNCA lanza error: si el tipo no se conoce, devuelve UnknownEvent; si los
  /// datos están incompletos, usa valores por defecto.
  static EventData parse(String type, Map<String, dynamic> p) { // type = texto guardado, p = datos guardados
    switch (type) { // según el tipo
      case EventTypes.departureConfirmed: return const DepartureConfirmedEvent(); // salida
      case EventTypes.missingItems: return MissingItemsEvent.fromPayload(p); // faltantes
      case EventTypes.arrived: return ArrivedEvent.fromPayload(p); // llegada
      case EventTypes.noAnswerReported: return const NoAnswerReportedEvent(); // "No me abren"
      case EventTypes.clientContacted: return ClientContactedEvent.fromPayload(p); // contacto con el cliente
      case EventTypes.officeCalled: return const OfficeCalledEvent(); // llamada a la oficina
      case EventTypes.noAnswerConfirmed: return const NoAnswerConfirmedEvent(); // "No me atendieron"
      case EventTypes.finished: return FinishedEvent.fromPayload(p); // terminé
      case EventTypes.extraAdded: return ExtraAddedEvent.fromPayload(p); // extra
      case EventTypes.requestAdded: return RequestAddedEvent.fromPayload(p); // solicitud
      case EventTypes.routeDelayReported: return RouteDelayReportedEvent.fromPayload(p); // retraso de ruta
      case EventTypes.warrantyDocumented: return WarrantyDocumentedEvent.fromPayload(p); // garantía
      case EventTypes.continueTomorrow: return ContinueTomorrowEvent.fromPayload(p); // sigo otro día
      case EventTypes.blocked: return BlockedEvent.fromPayload(p); // no pude seguir
      case EventTypes.helpRequested: return const HelpRequestedEvent(); // pidió ayuda
      default: return UnknownEvent(type, p); // un tipo que esta versión no conoce
    }
  }
}

// ---------------------------------------------------------------- Salida

class DepartureConfirmedEvent extends EventData { // "Llevo todo": la primera visita sale
  const DepartureConfirmedEvent(); // sin datos
  @override
  String get type => EventTypes.departureConfirmed; // su nombre
  @override
  Map<String, dynamic> toPayload() => {}; // no lleva datos
}

class MissingItemsEvent extends EventData { // renglones que le faltan al salir
  const MissingItemsEvent(this.items); // recibe la lista
  final List<MissingItem> items; // los renglones faltantes
  @override
  String get type => EventTypes.missingItems; // su nombre
  @override
  Map<String, dynamic> toPayload() => {'items': [for (final i in items) i.toJson()]}; // la lista de renglones
  factory MissingItemsEvent.fromPayload(Map<String, dynamic> p) => // lo reconstruye
      MissingItemsEvent([for (final m in readMaps(p, 'items')) MissingItem.fromJson(m)]); // cada renglón guardado
}

// ---------------------------------------------------------------- Llegada

class ArrivedEvent extends EventData { // "Llegué"
  const ArrivedEvent({required this.mode, this.lat, this.lng}); // modo y ubicación
  final ArrivalMode mode; // manual o automático
  final double? lat; // latitud (null si no hubo GPS)
  final double? lng; // longitud (null si no hubo GPS)
  @override
  String get type => EventTypes.arrived; // su nombre
  @override
  Map<String, dynamic> toPayload() => {'mode': mode.code, 'lat': lat, 'lng': lng}; // igual que antes
  factory ArrivedEvent.fromPayload(Map<String, dynamic> p) => ArrivedEvent( // lo reconstruye
        mode: ArrivalMode.tryFromCode(readString(p, 'mode')) ?? ArrivalMode.manual, // modo (manual si falta)
        lat: readNum(p, 'lat')?.toDouble(), // latitud
        lng: readNum(p, 'lng')?.toDouble(), // longitud
      );
}

// ---------------------------------------------------------------- "No me abren"

class NoAnswerReportedEvent extends EventData { // "No me abren": avisa a la oficina
  const NoAnswerReportedEvent(); // sin datos
  @override
  String get type => EventTypes.noAnswerReported; // su nombre
  @override
  Map<String, dynamic> toPayload() => {}; // no lleva datos
}

class ClientContactedEvent extends EventData { // intento de contactar al cliente
  const ClientContactedEvent(this.channel); // por qué canal
  final ContactChannel channel; // llamada o WhatsApp
  @override
  String get type => EventTypes.clientContacted; // su nombre
  @override
  Map<String, dynamic> toPayload() => {'channel': channel.code}; // igual que antes
  factory ClientContactedEvent.fromPayload(Map<String, dynamic> p) => // lo reconstruye
      ClientContactedEvent(ContactChannel.tryFromCode(readString(p, 'channel')) ?? ContactChannel.call); // llamada si falta
}

class OfficeCalledEvent extends EventData { // intento de llamar a la oficina
  const OfficeCalledEvent(); // sin datos
  @override
  String get type => EventTypes.officeCalled; // su nombre
  @override
  Map<String, dynamic> toPayload() => {}; // no lleva datos
}

class NoAnswerConfirmedEvent extends EventData { // "No me atendieron": cierra la visita
  const NoAnswerConfirmedEvent(); // sin datos
  @override
  String get type => EventTypes.noAnswerConfirmed; // su nombre
  @override
  Map<String, dynamic> toPayload() => {}; // no lleva datos
}

// ---------------------------------------------------------------- Extras y solicitudes

class ExtraAddedEvent extends EventData { // un extra que se hizo en la visita
  const ExtraAddedEvent(this.item); // el renglón
  final ExtraItem item; // los datos del extra
  String get name => item.name; // atajo: nombre
  num get quantity => item.quantity; // atajo: cantidad
  bool get notInstalled => item.notInstalled; // atajo: ¿no se instaló?
  @override
  String get type => EventTypes.extraAdded; // su nombre
  @override
  Map<String, dynamic> toPayload() => item.toPayload(); // los datos del extra
  factory ExtraAddedEvent.fromPayload(Map<String, dynamic> p) => ExtraAddedEvent(ExtraItem.fromPayload(p)); // lo reconstruye
}

class RequestAddedEvent extends EventData { // algo para cotizar después
  const RequestAddedEvent({ // constructor
    required this.description, // qué se pidió
    required this.origin, // de dónde viene
    this.requestedByText, // quién la pidió, escrito a mano (solo con "Solicitud después")
    this.item, // el extra del que nació (solo si fue un extra rechazado)
  });
  final String description; // descripción
  final RequestOrigin origin; // origen
  final String? requestedByText; // nombre escrito a mano
  final ExtraItem? item; // datos del extra, si nació de uno
  @override
  String get type => EventTypes.requestAdded; // su nombre
   @override
  Map<String, dynamic> toPayload() { // en sus dos variantes
    final it = item; // atajo local
    if (it != null) return {...it.toPayload(), 'description': description, 'origin': origin.code}; // nació de un extra: sus datos más descripción y origen
    return {'description': description, 'requester_text': requestedByText, 'origin': origin.code}; // creada con "Solicitud después" (ahora con su propio nombre de llave)
  }
  factory RequestAddedEvent.fromPayload(Map<String, dynamic> p) { // lo reconstruye
    final fromExtra = p.containsKey('source'); // si trae "source", nació de un extra
    return RequestAddedEvent( // arma el evento
      description: readString(p, 'description') ?? '', // descripción
      origin: RequestOrigin.tryFromCode(readString(p, 'origin')) ?? RequestOrigin.cannotDoNow, // origen
      requestedByText: fromExtra ? null : (readString(p, 'requester_text') ?? readString(p, 'requested_by')), // al leer, también acepta la llave vieja
      item: fromExtra ? ExtraItem.fromPayload(p) : null, // los datos del extra, si los hay
    );
  }
}

class RouteDelayReportedEvent extends EventData { // aviso al jefe: un extra retrasa las visitas
  const RouteDelayReportedEvent({required this.minutes, this.reason = 'extra', this.extraName}); // constructor
  final int minutes; // minutos de retraso
  final String reason; // por qué (hoy siempre 'extra')
  final String? extraName; // qué extra lo causa
  @override
  String get type => EventTypes.routeDelayReported; // su nombre
  @override
  Map<String, dynamic> toPayload() => {'minutes': minutes, 'reason': reason, 'extra_name': extraName}; // igual que antes
  factory RouteDelayReportedEvent.fromPayload(Map<String, dynamic> p) => RouteDelayReportedEvent( // lo reconstruye
        minutes: readInt(p, 'minutes') ?? 0, // minutos (0 si falta)
        reason: readString(p, 'reason') ?? 'extra', // motivo
        extraName: readString(p, 'extra_name'), // nombre del extra
      );
}

// ---------------------------------------------------------------- Cierre

class FinishedEvent extends EventData { // "Terminé el trabajo"
  const FinishedEvent({this.confirmedBy, this.confirmedRole}); // quién confirmó los extras (opcional)
  final String? confirmedBy; // nombre del contacto que confirmó
  final String? confirmedRole; // su cargo
  @override
  String get type => EventTypes.finished; // su nombre
  @override
  Map<String, dynamic> toPayload() { // vacío si no hubo extras
    final by = confirmedBy; // atajo local
    final role = confirmedRole; // atajo local
    return { // los datos, solo los que existen
      if (by != null) 'extras_confirmed_by': by, // quién confirmó
      if (role != null && role.isNotEmpty) 'extras_confirmed_role': role, // su cargo
    };
  }
  factory FinishedEvent.fromPayload(Map<String, dynamic> p) => FinishedEvent( // lo reconstruye
        confirmedBy: readString(p, 'extras_confirmed_by'), // quién confirmó
        confirmedRole: readString(p, 'extras_confirmed_role'), // su cargo
      );
}

class WarrantyDocumentedEvent extends EventData { // bloque de garantía guardado
  const WarrantyDocumentedEvent({this.cause, this.serial}); // causa y serial
  final WarrantyCause? cause; // causa (null si el código guardado no se reconoce)
  final String? serial; // número de serie escrito
  @override
  String get type => EventTypes.warrantyDocumented; // su nombre
  @override
  Map<String, dynamic> toPayload() => {'cause': cause?.code, 'serial': serial}; // igual que antes
  factory WarrantyDocumentedEvent.fromPayload(Map<String, dynamic> p) => WarrantyDocumentedEvent( // lo reconstruye
        cause: WarrantyCause.tryFromCode(readString(p, 'cause')), // causa
        serial: readString(p, 'serial'), // serial
      );
}

class ContinueTomorrowEvent extends EventData { // "Sigo otro día"
  const ContinueTomorrowEvent({ // constructor
    required this.materials, // material usado hoy
    required this.leftOnSite, // qué se queda en el sitio
    required this.missing, // qué falta por hacer
    required this.laidCable, // ¿se tendió cable?
  });
  final List<MaterialUsed> materials; // material usado
  final String leftOnSite; // lo que se queda
  final String missing; // lo que falta
  final bool laidCable; // si tendió cable
  @override
  String get type => EventTypes.continueTomorrow; // su nombre
  @override
  Map<String, dynamic> toPayload() => { // igual que antes
        'materials_used': [for (final m in materials) m.toJson()], // material usado
        'left_on_site': leftOnSite, // lo que se queda
        'missing': missing, // lo que falta
        'laid_cable': laidCable, // si tendió cable
      };
  factory ContinueTomorrowEvent.fromPayload(Map<String, dynamic> p) => ContinueTomorrowEvent( // lo reconstruye
        materials: [for (final m in readMaps(p, 'materials_used')) MaterialUsed.fromJson(m)], // cada renglón usado
        leftOnSite: readString(p, 'left_on_site') ?? '', // lo que se queda
        missing: readString(p, 'missing') ?? '', // lo que falta
        laidCable: readBool(p, 'laid_cable') ?? false, // si tendió cable
      );
}

class BlockedEvent extends EventData { // "No pude seguir"
  const BlockedEvent({required this.reason, this.incidentKind, required this.note}); // constructor
  final BlockReason reason; // motivo
  final IncidentKind? incidentKind; // subtipo, solo si es incidente
  final String note; // nota escrita
  @override
  String get type => EventTypes.blocked; // su nombre
  @override
  Map<String, dynamic> toPayload() => // igual que antes
      {'reason': reason.code, 'incident_kind': incidentKind?.code, 'note': note};
  factory BlockedEvent.fromPayload(Map<String, dynamic> p) => BlockedEvent( // lo reconstruye
        reason: BlockReason.tryFromCode(readString(p, 'reason')) ?? BlockReason.other, // motivo ("otro" si falta)
        incidentKind: IncidentKind.tryFromCode(readString(p, 'incident_kind')), // subtipo
        note: readString(p, 'note') ?? '', // nota
      );
}

class HelpRequestedEvent extends EventData { // pidió ayuda al ingeniero
  const HelpRequestedEvent(); // sin datos
  @override
  String get type => EventTypes.helpRequested; // su nombre
  @override
  Map<String, dynamic> toPayload() => {}; // no lleva datos
}

// ---------------------------------------------------------------- Desconocido

class UnknownEvent extends EventData { // un tipo que esta versión de la app no conoce
  const UnknownEvent(this.rawType, this.payload); // guarda el texto y los datos tal cual
  final String rawType; // el tipo original
  final Map<String, dynamic> payload; // los datos originales
  @override
  String get type => rawType; // devuelve el tipo original
  @override
  Map<String, dynamic> toPayload() => payload; // devuelve los datos originales sin tocar
}