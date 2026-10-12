import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/data/local/outbox_repository.dart';
import 'package:telyser_app/data/local/settings_store.dart';
import 'package:telyser_app/domain/app_settings.dart';

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


final databaseProvider = Provider<AppDatabase>((ref) {
  final db= AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final outboxRepositoryProvider = Provider<OutboxRepository>(
    (ref) => OutboxRepository(ref.watch(databaseProvider)));

final settingsStoreProvider = Provider<SettingsStore>(
    (ref) => SettingsStore(ref.watch(databaseProvider)));

    // Para conectar la API real: cambiar esta línea, igual que las otras dos.
final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => MockSettingsRepository());

/// Intenta descargar los parámetros y los guarda. Sin señal usa los últimos
/// guardados en el teléfono. Si nunca se descargaron, falla (no inventa valores).
final settingsProvider = FutureProvider<AppSettings>((ref) async {
  ref.watch(sessionProvider);
  final store = ref.watch(settingsStoreProvider);
  try {
    final fresh = await ref.watch(settingsRepositoryProvider).fetch();
    await store.save(fresh);
    return fresh;
  } catch (_) {
    final local = await store.load();
    if (local != null) return local;
    rethrow;
  }
});