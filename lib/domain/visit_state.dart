import 'package:telyser_app/domain/enums.dart';
import 'package:telyser_app/domain/event_types.dart';
import 'package:telyser_app/domain/models.dart';

/// Una acción de la cola, sin depender de Drift (así se prueba fácil).
class VisitEvent { 
  const VisitEvent({ 
    required this.type, // tipo de acción
    required this.occurredAt, // hora en que pasó (UTC)
    this.visitId, // visita a la que pertenece
    this.payload = const {}, // datos extra (nombre del extra, cantidad, canal,etc)
  });
  final String type; // tipo de acción
  final int? visitId; 
  final DateTime occurredAt; // hora
  final Map<String, dynamic> payload; // datos extra de la acción / opcional
}

/// Estado real de la ruta = lo descargado + las acciones de la cola, en orden.
/// Cuenta también las acciones en gracia: la pantalla cambia al instante y, si
/// el técnico deshace, la fila se borra y el estado regresa solo.
DayRoute applyEvents(DayRoute route, List<VisitEvent> events) {
  final visits = List<Visit>.of(route.visits);

  Visit? byId(int? id) {
    for (final v in visits) {
      if(v.id == id) return v;
    }
    return null;
  }
  
  void replace(Visit v) {
    final i = visits.indexWhere((x) => x.id == v.id);
    visits[i] = v;
  }

  // Al cerrar una visita, la siguiente por hacer pasa a En camino
  // (salvo que ya haya una En camino o En sitio, por ejemplo fuera de orden).
  void startNext() {
    final busy = visits.any(
      (v) => v.status == VisitStatus.enRoute || v.status == VisitStatus.onSite);
    if (busy) return;
    for(final v in visits) {
      if (v.status == VisitStatus.pending) {
        replace(v.copyWith(status: VisitStatus.enRoute));
        return;
      }
    }
  }

  void close(Visit? v, VisitResult result) {
    if(v == null || v.status == VisitStatus.done) return;
    replace(v.copyWith(status: VisitStatus.done, result: result));
    startNext();
  }


  for (final e in events) {
    final v = byId(e.visitId);
    switch (e.type) {
      case EventTypes.departureConfirmed:
        if(v != null && v.status == VisitStatus.pending) {
          replace(v.copyWith(status: VisitStatus.enRoute));
        }
      case EventTypes.arrived:
        if(v != null && v.status != VisitStatus.done) {
          replace(v.copyWith(status: VisitStatus.onSite, arrivedAt: e.occurredAt));
        }
      case EventTypes.finished:
        close(v, VisitResult.finished);
      case EventTypes.continueTomorrow:
        close(v, VisitResult.continueLater);
      case EventTypes.blocked:
        close(v, VisitResult.blocked);
      case EventTypes.noAnswerConfirmed:
        close(v, VisitResult.noAnswer);
      default: 
        break; // no_answer_reported y demás no cambian el estado
    }
  }
  return DayRoute(date: route.date, visits: visits);
}