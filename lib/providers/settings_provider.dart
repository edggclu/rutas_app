import 'package:flutter_riverpod/flutter_riverpod.dart'; // FutureProvider

import '../domain/models/app_settings.dart'; // AppSettings
import 'infra_providers.dart'; // repositorio y almacén de parámetros
import 'session_provider.dart'; // sessionProvider

/// Parámetros: se descargan y se guardan; sin señal se usan los últimos guardados.
final settingsProvider = FutureProvider<AppSettings>((ref) async { // se calcula una vez y se comparte
  ref.watch(sessionProvider); // si cambia la sesión, se vuelve a calcular
  final store = ref.watch(settingsStoreProvider); // el almacén local
  try { // primero se intenta con el servidor
    final fresh = await ref.watch(settingsRepositoryProvider).fetch(); // descarga los parámetros
    await store.save(fresh); // los guarda en el teléfono
    return fresh; // los entrega
  } catch (_) { // sin señal o error
    final local = await store.load(); // lee los últimos guardados
    if (local != null) return local; // si los hay, los usa
    rethrow; // si nunca se descargaron, falla (no se inventan valores)
  }
});