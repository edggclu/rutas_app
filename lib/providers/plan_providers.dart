import 'package:flutter_riverpod/flutter_riverpod.dart'; // Provider

import '../application/plan_actions.dart'; // las acciones del ingeniero
import '../domain/models/models.dart'; // Plan
import 'infra_providers.dart'; // planRepositoryProvider
import 'route_providers.dart'; // myDayBaseProvider, myDayProvider

/// Acciones sobre el plan. Tras guardar, la ruta se vuelve a pedir.
final planActionsProvider = Provider<PlanActions>((ref) => PlanActions(
      ref.watch(planRepositoryProvider),
      onChanged: () => ref.invalidate(myDayBaseProvider),
    ));

/// El plan actual de un trabajo (null si no tiene o la ruta aún no carga).
final jobPlanProvider = Provider.family<Plan?, int>((ref, jobId) {
  final route = ref.watch(myDayProvider).value;
  if (route == null) return null;
  for (final v in route.visits) {
    if (v.job.id == jobId) return v.job.plan;
  }
  return null;
});
