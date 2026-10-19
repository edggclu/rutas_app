import 'package:telyser_app/domain/event_types.dart';
import 'package:telyser_app/domain/visit_state.dart';

/// De dónde salió el material del extra.
enum ExtraSource { // opciones del formulario
  jobReserved('job_reserved', 'Apartado del trabajo'), // material que Axel separo para este trabajo
  ownStock('own_stock', 'Mi material'), // lo que el técnico trae en su camioneta (genera reposición)
  boughtOnRoute('bought_on_route', 'Compra en ruta'); // lo compró en el camino

  const ExtraSource(this.code, this.label); 
  final String code; // texto que viaja al servidor
  final String label; // texto que ve el técnico
}

/// Por que se hizo el extra.
enum ExtraReason {
  clientAsked('client_asked', 'Lo pidió el cliente'), // el cliente lo pidió
  siteRequired('site_required', 'Lo exigió el sitio'); // el sitio lo exigía (por ejemplo, por una condicion del lugar)

  const ExtraReason(this.code, this.label); 
  final String code; // texto que viaja al servidor
  final String label; // texto que ve el técnico
}

/// Que pasa con un extra al guardarlo.
enum ExtraOutcome { 
  register, // se hace y se anota
  laterOtherPerson, // lo pidio otra persona: no se hace, queda como solicitud
  laterCreditHold, // cliente con saldo vencido y es equipo: no se hace, queda como solicitud
}

/// Lo que el técnico lleno en el formulario "Agregar extra".
class ExtraDraft { 
  const ExtraDraft({
    required this.name, 
    this.productId, // id del catálogo (null si lo escribió a mano)
    required this.quantity, // cantidad
    this.unit, // 'piece' o 'service' (null si lo escribió a mano)
    required this.source, // de dónde salió
    required this.reason, // por qué
    required this.requestedByAuthorized, // true = lo pidio el contacto autorizado
    this.isEquipment = true, // si es equipo; sin catalogo se asume que sí (lado seguro)
    this.notInstalled = false, // true = algo que NO se instaló
    this.delayMinutes, // minutos que retrasará las siguientes visitas (null = no retrasa)
  });

  final String name; // nombre o descripción
  final int? productId; // id del catálogo
  final num quantity; // cantidad
  final String? unit; // unidad del producto
  final ExtraSource source; // origen del material
  final ExtraReason reason; // motivo
  final bool requestedByAuthorized; // quién lo pidió
  final bool isEquipment; // ¿es equipo?
  final bool notInstalled; // ¿es una nota de "no se instaló"?
  final int? delayMinutes; // retraso estimado
}

/// Aplica las reglas del documento. El orden importa: si lo pide otra persona,
/// no se mira nada más.
ExtraOutcome decideExtra({
  required bool requestedByAuthorized, // ¿lo pidió el contacto autorizado?
  required bool clientOverdue, // ¿el cliente tiene saldo vencido?
  required bool isEquipment, // ¿es equipo?
  required bool notInstalled, // ¿es una nota de "no se instaló"?
}) {
  if (!requestedByAuthorized) return ExtraOutcome.laterOtherPerson; // regla 1: solo el contacto autorizado pide extras
  if (clientOverdue && isEquipment && !notInstalled) { // regla 2: saldo vencido + equipo que sí se instalaría
    return ExtraOutcome.laterCreditHold; // requiere autorización: por ahora queda como solicitud
  }
  return ExtraOutcome.register; // en cualquier otro caso se hace y se anota
}

/// Muestra una cantidad sin ".0" cuando es entera (2.0 -> "2", 1.5 -> "1.5").
String quantityText(num q) => q % 1 == 0 ? q.toInt().toString() : q.toString(); // entero sin decimales

/// Un extra ya guardado, listo para mostrarse en pantalla.
class ExtraEntry { // renglón de la lista de extras
  const ExtraEntry({required this.name, required this.quantity, required this.notInstalled}); // constructor
  final String name; // nombre
  final num quantity; // cantidad
  final bool notInstalled; // ¿es una nota de "no se instaló"?
  String get label => '${quantityText(quantity)} × $name'; // ej. "1 × Cámara IP 4 MP"
}

/// Una solicitud para después ya guardada.
class RequestEntry { // renglón de la lista de solicitudes
  const RequestEntry({required this.description, required this.origin}); // constructor
  final String description; // qué pidió el cliente
  final String origin; // 'other_person', 'credit_hold' o 'cannot_do_now'
}

/// Extras de una visita, sacados de la cola (incluye los que siguen en gracia).
List<ExtraEntry> extrasOf(List<VisitEvent> events, int visitId) => [ // devuelve la lista
      for (final e in events) // recorre todas las acciones
        if (e.visitId == visitId && e.type == EventTypes.extraAdded) // solo extras de esta visita
          ExtraEntry( // arma el renglón
            name: (e.payload['name'] as String?) ?? '', // nombre
            quantity: (e.payload['quantity'] as num?) ?? 1, // cantidad (1 si falta)
            notInstalled: (e.payload['not_installed'] as bool?) ?? false, // ¿no se instaló?
          ),
    ];

/// Solicitudes para después de una visita, sacadas de la cola.
List<RequestEntry> requestsOf(List<VisitEvent> events, int visitId) => [ // devuelve la lista
      for (final e in events) // recorre todas las acciones
        if (e.visitId == visitId && e.type == EventTypes.requestAdded) // solo solicitudes de esta visita
          RequestEntry( // arma el renglón
            description: (e.payload['description'] as String?) ?? '', // descripción
            origin: (e.payload['origin'] as String?) ?? 'cannot_do_now', // de dónde viene
          ),
    ];