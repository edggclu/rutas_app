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

/// De dónde sale la lista de salida de una visita (en este orden de prioridad:
/// plan del ingeniero, cotización, nada).
enum ChecklistSource {
  plan,
  quote,
  none;

  static ChecklistSource parse(String? s) {
    switch (s) {
      case 'plan':
        return ChecklistSource.plan;
      case 'quote':
        return ChecklistSource.quote;
      default:
        return ChecklistSource.none;
    }
  }
}
/// Un renglón es material (se consume o se instala) o herramienta (se regresa).
enum ChecklistKind {
  material,
  tool;

  static ChecklistKind parse(String? s) => 
    s == 'tool' ?  ChecklistKind.tool : ChecklistKind.material;
}
/// Tipo de cliente (A, B o C). El técnico lo usa, junto con la ruta sugerida, para decidir por
/// dónde empezar. Un valor que la app no conoce se lee como "sin tipo".
enum ClientTier {
  a('A'),
  b('B'),
  c('C');

  const ClientTier(this.code);
  final String code;

  static ClientTier? tryParse(String? s) {
    for (final t in values) {
      if (t.code == s) return t;
    }
    return null;
  }
}
