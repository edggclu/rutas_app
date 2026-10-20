import 'enums.dart'; // VisitStatus y VisitResult
import 'events/event_data.dart'; // las clases de evento
import 'models.dart'; // DayRoute y Visit

/// Una acción de la cola, sin depender de Drift (así se prueba fácil).
/// Guarda el tipo y los datos TAL COMO están en la base, y ofrece `data` con
/// la clase tipada para leerlos sin errores de escritura.
class VisitEvent { // datos de una acción
  /// Desde la base: tipo y mapa crudos. `data` se calcula solo.
  VisitEvent({ // constructor principal
    required this.type, // tipo de acción (texto guardado)
    required this.occurredAt, // hora en que pasó (UTC)
    this.visitId, // visita a la que pertenece
    this.payload = const {}, // datos extra (texto guardado)
  }) : data = EventData.parse(type, payload); // los convierte a la clase tipada

  /// Desde una clase tipada (para pruebas y código nuevo).
  VisitEvent.of( // constructor alterno
    EventData d, { // el evento tipado
    required this.occurredAt, // hora en que pasó (UTC)
    this.visitId, // visita
  })  : type = d.type, // el tipo sale de la clase
        payload = d.toPayload(), // los datos salen de la clase
        data = d; // ya está tipado

  final String type; // tipo de acción (crudo)
  final int? visitId; // visita
  final DateTime occurredAt; // hora
  final Map<String, dynamic> payload; // datos extra (crudos)
  final EventData data; // los datos tipados: lo que debe usar el código de dominio
}

/// Estado real de la ruta = lo descargado + las acciones de la cola, en orden.
/// Cuenta también las acciones en gracia: la pantalla cambia al instante y, si
/// el técnico deshace, la fila se borra y el estado regresa solo.
DayRoute applyEvents(DayRoute route, List<VisitEvent> events) { // devuelve la ruta con el estado calculado
  final visits = List<Visit>.of(route.visits); // copia de las visitas (ya ordenadas por `order`)

  Visit? byId(int? id) { // busca una visita por su id
    for (final v in visits) { // recorre las visitas
      if (v.id == id) return v; // la encontró
    }
    return null; // no está en la ruta
  }

  void replace(Visit v) { // reemplaza una visita por su versión nueva
    final i = visits.indexWhere((x) => x.id == v.id); // dónde está
    visits[i] = v; // la cambia
  }

  // Al cerrar una visita, la siguiente por hacer pasa a En camino
  // (salvo que ya haya una En camino o En sitio, por ejemplo fuera de orden).
  void startNext() { // arranca la siguiente
    final busy = visits.any( // ¿ya hay una visita activa?
        (v) => v.status == VisitStatus.enRoute || v.status == VisitStatus.onSite);
    if (busy) return; // si la hay, no hace nada
    for (final v in visits) { // busca la primera por hacer
      if (v.status == VisitStatus.pending) { // la encontró
        replace(v.copyWith(status: VisitStatus.enRoute)); // la pone En camino
        return; // termina
      }
    }
  }

  void close(Visit? v, VisitResult result) { // cierra una visita con un resultado
    if (v == null || v.status == VisitStatus.done) return; // si no existe o ya está cerrada, nada
    replace(v.copyWith(status: VisitStatus.done, result: result)); // la deja Hecha
    startNext(); // y arranca la siguiente
  }

  for (final e in events) { // en el orden en que pasaron
    final v = byId(e.visitId); // la visita de esta acción
    // Sin `default`: si agregas una clase de evento nueva, el compilador marca
    // este switch hasta que decidas qué hace con el estado.
    switch (e.data) { // según la clase del evento
      case DepartureConfirmedEvent(): // salida confirmada
        if (v != null && v.status == VisitStatus.pending) { // si estaba por hacer
          replace(v.copyWith(status: VisitStatus.enRoute)); // pasa a En camino
        }
      case ArrivedEvent(): // llegada
        if (v != null && v.status != VisitStatus.done) { // si no estaba cerrada
          replace(v.copyWith(status: VisitStatus.onSite, arrivedAt: e.occurredAt)); // pasa a En sitio con la hora
        }
      case FinishedEvent(): // terminó el trabajo
        close(v, VisitResult.finished); // la cierra
      case ContinueTomorrowEvent(): // sigue otro día
        close(v, VisitResult.continueLater); // la cierra
      case BlockedEvent(): // no pudo seguir
        close(v, VisitResult.blocked); // la cierra
      case NoAnswerConfirmedEvent(): // nadie atendió
        close(v, VisitResult.noAnswer); // la cierra
      case MissingItemsEvent() || // estos eventos solo viajan al servidor:
          NoAnswerReportedEvent() ||
          ClientContactedEvent() ||
          OfficeCalledEvent() ||
          ExtraAddedEvent() ||
          RequestAddedEvent() ||
          RouteDelayReportedEvent() ||
          WarrantyDocumentedEvent() ||
          HelpRequestedEvent() ||
          UnknownEvent():
        break; // no cambian el estado de la visita
    }
  }
  return DayRoute(date: route.date, visits: visits); // la ruta con el estado ya calculado
}