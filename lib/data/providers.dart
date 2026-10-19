import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:telyser_app/data/local/media/media_repository.dart';
import 'package:telyser_app/data/visit_actions.dart';

import '../domain/app_settings.dart';
import '../domain/models.dart';
import '../domain/visit_state.dart';
import 'local/app_database.dart';
import 'local/outbox_repository.dart';
import 'local/route_store.dart';
import 'local/settings_store.dart';
import 'mock/mock_repositories.dart';
import 'repositories.dart';
import 'location_service.dart'; // el servicio de ubicación

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
          VisitEvent( // una acción de la cola
            type: r.type, // tipo
            visitId: r.visitId, // visita
            occurredAt: r.occurredAtUtc.toUtc(), // hora, normalizada a UTC
            payload: jsonDecode(r.payloadJson) as Map<String, dynamic>, // datos extra (nombre, cantidad,etc)
          ),
      ]);
});

/// Lo que ven las pantallas: ruta del servidor + acciones de la cola.
final myDayProvider = Provider<AsyncValue<DayRoute>>((ref) {
  final base = ref.watch(myDayBaseProvider);
  final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[];
  return base.whenData((route) => applyEvents(route, events));
});

/// El servicio de ubicacion real. En tests se sustituye por uno falso.
final locationServiceProvider = Provider<LocationService>(
  (ref) => DeviceLocationService()); // la versión que usa el GPS

  /// Acciones del técnico (encolan eventos).
  final visitActionsProvider = Provider<VisitActions> ((ref) => VisitActions(
    ref.watch(outboxRepositoryProvider), // le da la cola 
    () async => (await ref.read(settingsProvider.future)).undoSeconds, // le da cómo leer los segundos de deshacer
     ref.watch(locationServiceProvider)
  )
);

/// Una visita por su id, siempre con el estado actual (servidor + cola).
final visitByIdProvider = Provider.family<Visit?, int> ((ref, id) { // family = uno por cada id
  final route = ref.watch(myDayProvider).value;
  if (route == null) return null; // todavía no carga: no hay visita
  for (final v in route.visits) { // recorre las visitas de la ruta
    if (v.id == id) return v; // la encontró: la devuelve
  }
  return null; // ninguna coincide con ese id
}); 

/// Reloj que avisa cada segundo. SOLO sirve para redibujar la cuenta regresiva
/// el tiempo real siempre se calcula desde la hora de llegada guardada
final tickProvider = StreamProvider.autoDispose<DateTime> (// autoDispose: se apaga al salir de la pantalla
  (ref) => Stream.periodic( // Stream que emite cada 1 segundo
    const Duration(seconds: 1),
    (_) => DateTime.now().toUtc()
  )

);
/// Repositorio de fotos. La carpeta base es la carpeta privada de la app.
final mediaRepositoryProvider = Provider<MediaRepository>( // crea y comparte el repositorio
    (ref) => MediaRepository( // lo construye
          ref.watch(databaseProvider), // con la base local
          baseDir: getApplicationDocumentsDirectory, // y la carpeta documentos de la app
        ));

/// Fotos de una visita (se actualiza sola al tomar una foto nueva).
final mediaForVisitProvider = StreamProvider.autoDispose // autoDispose: se apaga al salir de la pantalla
    .family<List<MediaQueueData>, int>( // family: una por cada id de visita
        (ref, visitId) => // recibe el id de la visita
            ref.watch(mediaRepositoryProvider).watchForVisit(visitId)); // escucha las fotos de esa visita

/// Catálogo de productos. Para la API real: cambiar esta linea.
final productRepositoryProvider = Provider<ProductRepository>( // crea y comparte el repositorio
    (ref) => MockProductRepository()); // por ahora, el de prueba