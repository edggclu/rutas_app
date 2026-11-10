import '../data/repositories.dart';
import '../domain/dispatch_rules.dart';
import '../domain/models/dispatch_models.dart';
import '../domain/session_errors.dart';

/// Acciones del jefe de ruta sobre las visitas. Necesitan señal: van directo al servidor, no por la
/// cola. Después de cada una (o si el servidor responde que algo ya cambió) avisa con [onChanged]
/// para que el tablero se vuelva a pedir.
class DispatchActions {
  DispatchActions(this._repo, {required void Function() onChanged, DateTime Function()? now})
      : _onChanged = onChanged,
        _now = now ?? DateTime.now;

  final DispatchRepository _repo;
  final void Function() _onChanged;
  final DateTime Function() _now;

  /// Programa un trabajo por asignar. Lanza [ArgumentError] si no cumple las reglas y
  /// [ConflictException] si otra persona ya lo programó.
  Future<void> scheduleVisit({
    required UnassignedJob job,
    required DateTime date,
    required int technicianId,
    Set<int> companionIds = const {},
    bool urgent = false,
  }) async {
    final issue = checkSchedule(
      job: job,
      technicianId: technicianId,
      date: date,
      today: _now(),
      companionIds: companionIds,
    );
    if (issue != null) throw ArgumentError(issue.name);
    await _run(() => _repo.createVisit(NewVisit(
          jobId: job.id,
          date: dateOnly(date),
          technicianId: technicianId,
          companionIds: companionIds.toList()..sort(),
          urgent: urgent,
        )));
  }

  /// Mueve una visita a otro día y/o a otro técnico. Lanza [ArgumentError] si no se puede y
  /// [ConflictException] si la visita ya empezó.
  Future<void> moveVisit({
    required DispatchVisit visit,
    required DateTime fromDate,
    required int fromTechnicianId,
    required DateTime toDate,
    required int toTechnicianId,
  }) async {
    final issue = checkMove(
      visit: visit,
      fromDate: fromDate,
      fromTechnicianId: fromTechnicianId,
      toDate: toDate,
      toTechnicianId: toTechnicianId,
      today: _now(),
    );
    if (issue != null) throw ArgumentError(issue.name);
    await _run(() => _repo.moveVisit(
          visitId: visit.id,
          date: dateOnly(toDate) == dateOnly(fromDate) ? null : dateOnly(toDate),
          technicianId: toTechnicianId == fromTechnicianId ? null : toTechnicianId,
        ));
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ConflictException {
      _onChanged(); // lo que se veía ya no es cierto: se vuelve a pedir
      rethrow;
    }
    _onChanged();
  }
}
