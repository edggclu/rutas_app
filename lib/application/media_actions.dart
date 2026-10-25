import '../data/local/media/media_repository.dart';
import '../domain/media_rules.dart';
import '../domain/models/media_item.dart';

/// Acciones del técnico sobre las fotos y videos que ya tomó. Son locales: no necesitan señal.
class MediaActions {
  MediaActions(this._repo);

  final MediaRepository _repo;

  /// Borra la foto o video (la fila y el archivo). Lanza si ya se subió al servidor.
  Future<void> delete(MediaItem item) async {
    if (!canDeleteMedia(item)) throw StateError('Ya se subió al servidor');
    await _repo.delete(item.id);
  }
}
