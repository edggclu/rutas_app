import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/dispatch_actions.dart';
import '../domain/models/dispatch_models.dart';
import 'infra_providers.dart';
import 'session_provider.dart';

/// El tablero del jefe de ruta. Se vuelve a pedir al cambiar de sesión o al jalar para actualizar.
final dispatchProvider = FutureProvider<DispatchBoard>((ref) {
  ref.watch(sessionProvider);
  return ref.watch(dispatchRepositoryProvider).fetch();
});

/// Las acciones del jefe de ruta. Tras cada una, el tablero se vuelve a pedir.
final dispatchActionsProvider = Provider<DispatchActions>((ref) => DispatchActions(
      ref.watch(dispatchRepositoryProvider),
      onChanged: () => ref.invalidate(dispatchProvider),
    ));
