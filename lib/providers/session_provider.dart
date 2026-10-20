import 'package:flutter_riverpod/flutter_riverpod.dart'; // Notifier y NotifierProvider

import '../domain/models.dart'; // Session
import 'infra_providers.dart'; // authRepositoryProvider

/// Guarda la sesión actual (null = nadie ha iniciado sesión).
class SessionNotifier extends Notifier<Session?> { // un Notifier guarda un valor que cambia
  @override
  Session? build() => null; // al arrancar, sin sesión

  Future<void> login(String username, String password) async { // inicia sesión
    final session = // la sesión que devuelve el servidor
        await ref.read(authRepositoryProvider).login(username, password); // pide el login
    state = session; // la guarda: todas las pantallas que la observan se redibujan
  }

  Future<void> logout() async { // cierra sesión
    await ref.read(authRepositoryProvider).logout(); // avisa al servidor
    state = null; // se borra la sesión
  }
}

final sessionProvider = // lo que las pantallas observan
    NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new); // crea el Notifier