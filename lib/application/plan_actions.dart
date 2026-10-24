import '../data/repositories.dart'; // PlanRepository
import '../domain/models/models.dart'; // Plan
import '../domain/plan_rules.dart'; // canSavePlan

/// Acciones del ingeniero sobre el plan de un trabajo. Necesitan señal: van directo
/// al servidor, no por la cola. Después de guardar avisa con [onChanged] para que
/// la ruta se vuelva a pedir y todos vean el plan nuevo.
class PlanActions {
  PlanActions(this._repo, {required void Function() onChanged}) : _onChanged = onChanged;

  final PlanRepository _repo;
  final void Function() _onChanged;

  Future<void> save(int jobId, Plan plan) async {
    if (!canSavePlan(plan)) throw ArgumentError('El plan tiene renglones o pines vacíos');
    await _repo.save(jobId, plan);
    _onChanged();
  }
}
