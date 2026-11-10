import 'models/dispatch_models.dart';
import 'models/enums.dart';

/// Solo cuenta el día: la hora se descarta.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Por qué no se puede programar una visita nueva.
enum ScheduleIssue { jobNotReady, noTechnician, pastDate, companionIsResponsible }

/// Revisa los datos antes de crear la visita. El servidor vuelve a validar; esto evita viajes inútiles.
/// [today] se recibe como dato para poder probarlo.
ScheduleIssue? checkSchedule({
  required UnassignedJob job,
  required int? technicianId,
  required DateTime date,
  required DateTime today,
  Set<int> companionIds = const {},
}) {
  if (!job.canSchedule) return ScheduleIssue.jobNotReady; // el semáforo tiene una luz en rojo
  if (technicianId == null) return ScheduleIssue.noTechnician;
  if (dateOnly(date).isBefore(dateOnly(today))) return ScheduleIssue.pastDate;
  if (companionIds.contains(technicianId)) return ScheduleIssue.companionIsResponsible;
  return null;
}

/// Una visita solo se puede mover mientras no haya empezado.
bool canMoveVisit(DispatchVisit v) => v.status == VisitStatus.pending;

/// Por qué no se puede mover una visita.
enum MoveIssue { notMovable, pastDate, nothingChanged }

/// Revisa un cambio de día o de técnico. [fromDate] y [fromTechnicianId] son donde está hoy.
MoveIssue? checkMove({
  required DispatchVisit visit,
  required DateTime fromDate,
  required int fromTechnicianId,
  required DateTime toDate,
  required int toTechnicianId,
  required DateTime today,
}) {
  if (!canMoveVisit(visit)) return MoveIssue.notMovable;
  if (dateOnly(toDate).isBefore(dateOnly(today))) return MoveIssue.pastDate;
  if (dateOnly(toDate) == dateOnly(fromDate) && toTechnicianId == fromTechnicianId) return MoveIssue.nothingChanged;
  return null;
}
