import 'models/enums.dart';
import 'models/models.dart';

/// El texto del estado de una visita. Una visita cerrada solo es "Hecha" si se terminó:
/// si quedó pendiente, detenida o sin atender, se dice eso, para que nadie crea que ya está.
String visitStatusLabel(Visit v) => statusText(v.status, v.result, v.dayNumber);

/// Lo mismo a partir de los tres datos, para quien no tenga una [Visit] completa (la pantalla
/// del jefe de ruta). [dayNumber] solo se usa en "Sin terminar".
String statusText(VisitStatus status, VisitResult? result, int? dayNumber) {
  switch (status) {
    case VisitStatus.pending:
      return 'Por hacer';
    case VisitStatus.enRoute:
      return 'En camino';
    case VisitStatus.onSite:
      return 'En sitio';
    case VisitStatus.done:
      switch (result) {
        case VisitResult.continueLater:
          return dayNumber == null ? 'Sin terminar' : 'Sin terminar · Día $dayNumber';
        case VisitResult.blocked:
          return 'Detenida';
        case VisitResult.noAnswer:
          return 'Sin atender';
        case VisitResult.finished:
        case null:
          return 'Hecha';
      }
  }
}
