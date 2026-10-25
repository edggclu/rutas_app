import 'package:flutter_riverpod/flutter_riverpod.dart'; // Notifier y NotifierProvider

import '../domain/models/models.dart'; // Session
import '../domain/session_errors.dart'; // WrongAccountException
import 'infra_providers.dart'; // authRepositoryProvider

/// Guarda la sesión actual (null = nadie ha iniciado sesión).
class SessionNotifier extends Notifier<Session?> { // un Notifier guarda un valor que cambia
  @override
  Session? build() => null; // al arrancar, sin sesión

  Future<void> login(String username, String password) async { // inicia sesión
    final session = // la sesión que devuelve el servidor
        await ref.read(authRepositoryProvider).login(username, password); // pide el login
    final expired = ref.read(expiredUserProvider); // ¿venía de una sesión expirada?
    if (expired != null && session.user.id != expired.id) { // otra cuenta: las acciones sin enviar no son suyas
      await ref.read(authRepositoryProvider).logout(); // se cierra la sesión que acaba de abrir
      throw WrongAccountException(expired.name);
    }
    ref.read(expiredUserProvider.notifier).set(null); // ya volvió a entrar
    state = session; // la guarda: todas las pantallas que la observan se redibujan
  }

  Future<void> logout() async { // cierra sesión
    await ref.read(authRepositoryProvider).logout(); // avisa al servidor
    ref.read(expiredUserProvider.notifier).set(null); // salir a propósito no es expirar
    state = null; // se borra la sesión
  }

  /// El servidor respondió 401. Se sale sin avisarle (el token ya no sirve) y sin tocar la cola
  /// local: lo guardado se manda cuando el mismo usuario vuelva a entrar.
  void expire() {
    final current = state;
    if (current == null) return; // ya no hay sesión
    ref.read(expiredUserProvider.notifier).set(current.user);
    state = null;
  }
}

final sessionProvider = // lo que las pantallas observan
    NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new); // crea el Notifier

/// Quién tenía la sesión cuando expiró (null = no expiró). El login lo usa para mostrar el
/// aviso y para exigir la misma cuenta.
class ExpiredUserNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  void set(AppUser? user) => state = user;
}

final expiredUserProvider = NotifierProvider<ExpiredUserNotifier, AppUser?>(ExpiredUserNotifier.new);
