import 'models/enums.dart'; // VisitStatus
import 'models/models.dart'; // Visit

/// Por qué NO se puede marcar Llegué en una visita.
enum ArrivalBlock { // los dos motivos
  routeNotStarted, // todavía no confirmó la salida
  anotherVisitInProgress, // hay otra visita En camino o En sitio
}

/// La visita que está en curso (En camino o En sitio). null si ninguna.
Visit? visitInProgress(List<Visit> visits) { // visits = las visitas de la ruta, con su estado actual
  for (final v in visits) { // recorre las visitas
    if (v.status == VisitStatus.enRoute || v.status == VisitStatus.onSite) return v; // la primera en curso
  }
  return null; // ninguna en curso
}

/// ¿Por qué no se puede marcar Llegué en [visit]? null = sí se puede (o no aplica).
ArrivalBlock? arrivalBlock(Visit visit, List<Visit> visits) { // la regla completa
  if (visit.status == VisitStatus.done || visit.status == VisitStatus.onSite) return null; // ya llegó o ya terminó: no aplica
  if (visit.status == VisitStatus.enRoute) return null; // es la visita a la que va: sí puede
  final active = visitInProgress(visits); // ¿hay alguna en curso?
  if (active == null) return ArrivalBlock.routeNotStarted; // ninguna: todavía no salió
  return ArrivalBlock.anotherVisitInProgress; // esta está por hacer y hay otra en curso
}