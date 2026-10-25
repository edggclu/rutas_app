import 'models/media_item.dart';

/// Una foto o video se puede borrar mientras siga solo en el teléfono. Cuando ya se subió,
/// el servidor lo tiene y la app no puede quitarlo de allá (no hay ruta para eso).
bool canDeleteMedia(MediaItem item) => !item.sent;
