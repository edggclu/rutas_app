import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/application/media_actions.dart';
import 'package:telyser_app/application/visit_actions.dart';

import 'infra_providers.dart';
import 'settings_provider.dart';

/// Acciones del técnico (encolan eventos). Lee `undo_seconds` de los
/// parámetros descargados, nunca un número fijo.
final visitActionsProvider = Provider<VisitActions>((ref) => VisitActions( // crea las acciones
      ref.watch(outboxRepositoryProvider), // le da la cola
      () async => (await ref.read(settingsProvider.future)).undoSeconds, // le da cómo leer los segundos de deshacer
      ref.watch(locationServiceProvider), // le da el servicio de ubicación
    ));
    
/// Borra lo guardado en el teléfono (cola y fotos). Solo para la demo.
final demoResetProvider = Provider<Future<void> Function()>((ref) => () async { // devuelve una función que se ejecuta al llamarla
      await ref.read(outboxRepositoryProvider).clearAll(); // borra la cola: las visitas vuelven a su estado inicial
      await ref.read(mediaRepositoryProvider).clearAll(); // borra las fotos y videos
    });

/// Acciones sobre las fotos y videos ya tomados (borrar).
final mediaActionsProvider = Provider<MediaActions>(
    (ref) => MediaActions(ref.watch(mediaRepositoryProvider)));
