import 'package:flutter_riverpod/flutter_riverpod.dart'; // Provider: el mecanismo para compartir objetos
import 'package:path_provider/path_provider.dart'; // getApplicationDocumentsDirectory: carpeta privada de la app

import '../data/local/app_database.dart'; // la base de datos local
import '../data/local/media/media_repository.dart'; // fotos y videos
import '../data/local/outbox_repository.dart'; // la cola de acciones
import '../data/local/route_store.dart'; // la ruta del día guardada
import '../data/local/settings_store.dart'; // los parámetros guardados
import '../data/location_service.dart'; // el GPS
import '../data/mock/mock_repositories.dart'; // los repositorios de prueba
import '../data/repositories.dart'; // los contratos (interfaces)

// ---- Repositorios remotos. Para la API real: cambiar estas cuatro líneas. ----
final authRepositoryProvider = // inicio de sesión
    Provider<AuthRepository>((ref) => MockAuthRepository()); // hoy, el de prueba
final visitRepositoryProvider = // ruta del día
    Provider<VisitRepository>((ref) => MockVisitRepository()); // hoy, el de prueba
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