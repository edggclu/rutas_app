import 'models/models.dart';

/// Un plan se puede guardar si ningún renglón ni pin está vacío y todo renglón trae una cantidad positiva.
bool canSavePlan(Plan plan) {
  for (final i in plan.items) {
    if (i.text.trim().isEmpty) return false; // renglón sin nombre
    final q = i.quantity;
    if (q == null || q <= 0) return false; // sin cantidad, o cero o negativa
  }
  for (final p in plan.sketch?.pins ?? const <SketchPin>[]) {
    if (p.label.trim().isEmpty) return false; // pin sin etiqueta
  }
  return true;
}

/// El siguiente id libre para un renglón o pin nuevo (el servidor lo reasigna al guardar).
int nextLocalId(Iterable<int> ids) => ids.fold(0, (m, id) => id > m ? id : m) + 1;
