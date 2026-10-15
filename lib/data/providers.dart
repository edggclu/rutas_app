import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/app_settings.dart';
import '../domain/models.dart';
import '../domain/visit_state.dart';
import 'local/app_database.dart';
import 'local/outbox_repository.dart';
import 'local/route_store.dart';
import 'local/settings_store.dart';
import 'mock/mock_repositories.dart';
import 'repositories.dart';

// Para conectar la API real: cambiar estas tres líneas por las implementaciones HTTP.
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => MockAuthRepository());
final visitRepositoryProvider =
    Provider<VisitRepository>((ref) => MockVisitRepository());
final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => MockSettingsRepository());

// Base local
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
final outboxRepositoryProvider = Provider<OutboxRepository>(
    (ref) => OutboxRepository(ref.watch(databaseProvider)));
final settingsStoreProvider = Provider<SettingsStore>(
    (ref) => SettingsStore(ref.watch(databaseProvider)));
final routeStoreProvider =
    Provider<RouteStore>((ref) => RouteStore(ref.watch(databaseProvider)));

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

/// Parámetros: se descargan y se guardan; sin señal se usan los últimos guardados.
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

/// Ruta tal como la tiene el servidor. Con señal: descarga y guarda en el
/// teléfono. Sin señal: lee lo último guardado.
final myDayBaseProvider = FutureProvider<DayRoute>((ref) async {
  ref.watch(sessionProvider);
  final store = ref.watch(routeStoreProvider);
  final now = DateTime.now();
  try {
    final raw = await ref.watch(visitRepositoryProvider).fetchMyDay(now);
    await store.saveDay(raw);
    return DayRoute.fromJson(raw);
  } catch (_) {
    final local = await store.loadDay(DateFormat('yyyy-MM-dd').format(now));
    if (local != null) return local;
    rethrow;
  }
});

/// Acciones de la cola (incluidas las que siguen en gracia).
final visitEventsProvider = StreamProvider<List<VisitEvent>>((ref) {
  return ref.watch(outboxRepositoryProvider).watchAll().map((rows) => [
        for (final r in rows)
          VisitEvent(
            type: r.type,
            visitId: r.visitId,
            // Drift devuelve la hora en local: se normaliza a UTC.
            occurredAt: r.occurredAtUtc.toUtc(),
          ),
      ]);
});

/// Lo que ven las pantallas: ruta del servidor + acciones de la cola.
final myDayProvider = Provider<AsyncValue<DayRoute>>((ref) {
  final base = ref.watch(myDayBaseProvider);
  final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[];
  return base.whenData((route) => applyEvents(route, events));
});