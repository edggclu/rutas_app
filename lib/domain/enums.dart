/// Estados de una visita (lo que ve el técnico). No existe botón "en camino":
/// la app lo pone sola al confirmar la salida o al cerrar la visita anterior.
enum VisitStatus {
  pending,
  enRoute,
  onSite,
  done;

  static VisitStatus parse(String? s) {
    switch (s) {
      case 'en_route':
        return VisitStatus.enRoute;
      case 'on_site':
        return VisitStatus.onSite;
      case 'done':
        return VisitStatus.done;
      default:
        return VisitStatus.pending;
    }
  }
}

/// Los cuatro resultados con los que se cierra una visita.
enum VisitResult {
  finished,
  continueLater,
  blocked,
  noAnswer;

  static VisitResult? parse(String? s) {
    switch (s) {
      case 'finished':
        return VisitResult.finished;
      case 'continue':
        return VisitResult.continueLater;
      case 'blocked':
        return VisitResult.blocked;
      case 'no_answer':
        return VisitResult.noAnswer;
      default:
        return null;
    }
  }
}

enum JobType {
  installation,
  corrective,
  preventive;

  static JobType parse(String? s) {
    switch (s) {
      case 'installation':
        return JobType.installation;
      case 'preventive':
        return JobType.preventive;
      default:
        return JobType.corrective;
    }
  }
}

enum Priority {
  normal,
  urgent;

  static Priority parse(String? s) =>
      s == 'urgent' ? Priority.urgent : Priority.normal;
}

/// Quién paga: el cliente, Telyser (garantía) o el contrato (póliza).
enum Coverage {
  paid,
  warranty,
  policy;

  static Coverage parse(String? s) {
    switch (s) {
      case 'warranty':
        return Coverage.warranty;
      case 'policy':
        return Coverage.policy;
      default:
        return Coverage.paid;
    }
  }
}
