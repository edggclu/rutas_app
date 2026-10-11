import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'mock/mock_repositories.dart';
import 'repositories.dart';

// Para conectar la API real: cambiar estas dos líneas por las implementaciones HTTP.
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => MockAuthRepository());
final visitRepositoryProvider =
    Provider<VisitRepository>((ref) => MockVisitRepository());

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => null;

  Future<void> login(String username, String password) async {
    final session =
        await ref.read(authRepositoryProvider).login(username, password);
    state = session;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

/// Ruta del día del usuario con sesión iniciada.
final myDayProvider = FutureProvider<DayRoute>((ref) async {
  ref.watch(sessionProvider);
  return ref.watch(visitRepositoryProvider).myDay(DateTime.now());
});
