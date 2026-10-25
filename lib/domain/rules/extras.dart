import 'package:telyser_app/domain/format.dart';

import '../events/event_data.dart';
import '../models/extra_models.dart';
import 'visit_state.dart';

export '../models/extra_models.dart';

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


/// Un extra ya guardado, listo para mostrarse en pantalla.
class ExtraEntry { // renglón de la lista de extras
  const ExtraEntry({required this.name, required this.quantity, required this.notInstalled}); // constructor
  final String name; // nombre
  final num quantity; // cantidad
  final bool notInstalled; // ¿es una nota de "no se instaló"?
  String get label => '${formatNumber(quantity)} x $name'; // ej. "1 × Cámara IP 4 MP"
}

/// Una solicitud para después ya guardada.
class RequestEntry { // renglón de la lista de solicitudes
  const RequestEntry({required this.description, required this.origin}); // constructor
  final String description; // qué pidió el cliente
  final RequestOrigin origin; // de dónde viene
}

/// Extras de una visita, sacados de la cola (incluye los que siguen en gracia).
List<ExtraEntry> extrasOf(List<VisitEvent> events, int visitId) { // devuelve la lista
  final out = <ExtraEntry>[]; // aquí se junta
  for (final e in events) { // recorre todas las acciones
    final d = e.data; // el evento tipado
    if (e.visitId == visitId && d is ExtraAddedEvent) { // solo extras de esta visita
      out.add(ExtraEntry(name: d.name, quantity: d.quantity, notInstalled: d.notInstalled)); // arma el renglón
    }
  }
  return out; // la lista
}

/// Solicitudes para después de una visita, sacadas de la cola.
List<RequestEntry> requestsOf(List<VisitEvent> events, int visitId) { // devuelve la lista
  final out = <RequestEntry>[]; // aquí se junta
  for (final e in events) { // recorre todas las acciones
    final d = e.data; // el evento tipado
    if (e.visitId == visitId && d is RequestAddedEvent) { // solo solicitudes de esta visita
      out.add(RequestEntry(description: d.description, origin: d.origin)); // arma el renglón
    }
  }
  return out; // la lista
}