import '../data/repositories.dart'; // ReviewRepository
import '../domain/models/closing_models.dart'; // WarrantyCause
import '../domain/models/review_models.dart'; // ReviewJob
import '../domain/review_rules.dart'; // canValidate y canReturnJob

/// Acciones del ingeniero sobre trabajos terminados. Necesitan señal: van
/// directo al servidor, no por la cola. Después de cada una avisa con
/// [onChanged] para que la lista se vuelva a pedir.
class ReviewActions {
  ReviewActions(this._repo, {required void Function() onChanged}) : _onChanged = onChanged;

  final ReviewRepository _repo;
  final void Function() _onChanged;

  Future<void> validate(ReviewJob job) async {
    if (!canValidate(job)) throw StateError('Falta dictaminar la garantía'); // la regla también se aplica aquí
    await _repo.validate(job.id);
    _onChanged();
  }

  Future<void> returnJob(ReviewJob job, String note) async {
    if (!canReturnJob(note)) throw ArgumentError('La nota es obligatoria');
    await _repo.returnJob(job.id, note.trim());
    _onChanged();
  }

  Future<void> submitVerdict(ReviewJob job, WarrantyCause cause) async {
    await _repo.submitVerdict(job.id, cause);
    _onChanged();
  }
}