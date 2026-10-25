import 'models/review_models.dart';

/// Un trabajo se puede validar si no tiene un dictamen pendiente.
bool canValidate(ReviewJob job) => !job.needsVerdict;

/// Para regresar un trabajo la nota es obligatoria.
bool canReturnJob(String note) => note.trim().isNotEmpty;