import 'package:flutter_riverpod/flutter_riverpod.dart'; // los distintos tipos de provider

import '../application/review_actions.dart'; // las acciones del ingeniero
import '../domain/models/review_models.dart'; // ReviewJob
import 'infra_providers.dart'; // reviewRepositoryProvider
import 'session_provider.dart'; // sessionProvider


/// Trabajos por validar. Se vuelve a pedir al cambiar de sesión o tras una acción.
final reviewListProvider = FutureProvider<List<ReviewJob>>((ref) async {
  ref.watch(sessionProvider);
  return ref.watch(reviewRepositoryProvider).fetchPending();
});

/// Un trabajo por su id, con su estado actual. null si ya no está en la lista.
final reviewJobProvider = Provider.family<ReviewJob?, int>((ref, id) {
  final jobs = ref.watch(reviewListProvider).value;
  if (jobs == null) return null;
  for (final j in jobs) {
    if (j.id == id) return j;
  }
  return null;
});

/// Acciones del ingeniero. Tras cada una, la lista se invalida y se vuelve a pedir.
final reviewActionsProvider = Provider<ReviewActions>((ref) => ReviewActions(
      ref.watch(reviewRepositoryProvider),
      onChanged: () => ref.invalidate(reviewListProvider),
    ));
    