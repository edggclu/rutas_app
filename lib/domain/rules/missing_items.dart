import '../events/event_data.dart';
import '../models/event_models.dart';
import 'visit_state.dart';

/// Lo que todavía le falta al técnico para una visita: los renglones que marcó como faltantes al
/// salir, menos los que después dijo que ya consiguió. No bloquea nada: puede trabajar sin ellos.
List<MissingItem> pendingMissingItems(List<VisitEvent> events, int visitId) {
  final missing = <int, MissingItem>{}; // por id, para no repetir
  for (final e in events) {
    if (e.visitId != visitId) continue;
    final d = e.data;
    switch (d) {
      case MissingItemsEvent():
        for (final i in d.items) {
          missing[i.id] = i;
        }
      case ItemsObtainedEvent():
        d.itemIds.forEach(missing.remove);
      default:
        break;
    }
  }
  return missing.values.toList();
}
