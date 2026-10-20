import 'package:flutter_riverpod/flutter_riverpod.dart'; // Provider
import 'package:telyser_app/application/visit_actions.dart';

import 'infra_providers.dart'; // cola y ubicación
import 'settings_provider.dart'; // los parámetros (segundos para deshacer)

/// Acciones del técnico (encolan eventos). Lee `undo_seconds` de los
/// parámetros descargados, nunca un número fijo.
final visitActionsProvider = Provider<VisitActions>((ref) => VisitActions( // crea las acciones
      ref.watch(outboxRepositoryProvider), // le da la cola
      () async => (await ref.read(settingsProvider.future)).undoSeconds, // le da cómo leer los segundos de deshacer
      ref.watch(locationServiceProvider), // le da el servicio de ubicación
    ));