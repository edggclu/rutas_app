import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/local/app_database.dart';
import '../data/local/media/media_repository.dart';
import '../data/local/outbox_repository.dart';
import '../data/local/route_store.dart';
import '../data/local/settings_store.dart';
import '../data/location_service.dart';
import '../data/mock/mock_repositories.dart';
import '../data/repositories.dart';

// ---- Repositorios remotos. Para la API real: cambiar estas cuatro líneas. ----
final authRepositoryProvider = // inicio de sesión
    Provider<AuthRepository>((ref) => MockAuthRepository()); // hoy, el de prueba
final visitRepositoryProvider = // ruta del día
    Provider<VisitRepository>((ref) => MockVisitRepository(ref.watch(mockPlanStoreProvider))); // hoy, el de prueba
final settingsRepositoryProvider = // parámetros del servidor
    Provider<SettingsRepository>((ref) => MockSettingsRepository()); // hoy, el de prueba
final productRepositoryProvider = // catálogo de productos
    Provider<ProductRepository>((ref) => MockProductRepository()); // hoy, el de prueba

// ---- Base local ----
final databaseProvider = Provider<AppDatabase>((ref) { // la base SQLite del teléfono
  final db = AppDatabase(); // la abre (o la crea)
  ref.onDispose(db.close); // la cierra cuando ya no se necesite
  return db; // la comparte
});

final outboxRepositoryProvider = Provider<OutboxRepository>( // la cola de acciones
    (ref) => OutboxRepository(ref.watch(databaseProvider))); // construida con la base
final settingsStoreProvider = Provider<SettingsStore>( // guarda y lee los parámetros
    (ref) => SettingsStore(ref.watch(databaseProvider))); // construida con la base
final routeStoreProvider = Provider<RouteStore>( // guarda y lee la ruta del día
    (ref) => RouteStore(ref.watch(databaseProvider))); // construida con la base

final mediaRepositoryProvider = Provider<MediaRepository>( // fotos y videos
    (ref) => MediaRepository( // lo construye
          ref.watch(databaseProvider), // con la base
          baseDir: getApplicationDocumentsDirectory, // y la carpeta privada de la app
        ));

// ---- Dispositivo ----
final locationServiceProvider = Provider<LocationService>( // el GPS
    (ref) => DeviceLocationService()); // la versión real; en tests se sustituye

    
final reviewRepositoryProvider = // trabajos por validar
    Provider<ReviewRepository>((ref) => MockReviewRepository()); // hoy, el de prueba

final myJobsRepositoryProvider = // mis trabajos terminados
    Provider<MyJobsRepository>((ref) => MockMyJobsRepository()); // hoy, el de prueba


final mockPlanStoreProvider = Provider<MockPlanStore>((ref) => MockPlanStore()); // planes editados en la demo (solo prueba)
final planRepositoryProvider = // guardar el plan del trabajo
    Provider<PlanRepository>((ref) => MockPlanRepository(ref.watch(mockPlanStoreProvider))); // hoy, el de prueba


final notificationsRepositoryProvider = // avisos
    Provider<NotificationsRepository>((ref) => MockNotificationsRepository()); // hoy, el de prueba
