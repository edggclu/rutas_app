import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/media/media_repository.dart';
import '../data/local/outbox_repository.dart';
import '../data/local/route_store.dart';
import '../data/local/settings_store.dart';
import '../data/local/user_storage.dart';
import 'session_provider.dart';

// ---- Todo lo que se guarda en el teléfono es del usuario con la sesión abierta ----

/// El usuario que tiene la sesión abierta. Lo guardado en el teléfono solo se toca con sesión.
final currentUserIdProvider = Provider<int>((ref) {
  final id = ref.watch(sessionProvider.select((s) => s?.user.id));
  if (id == null) throw StateError('Sin sesión: lo guardado en el teléfono es de cada usuario');
  return id;
});

/// Cómo se abre la base de un usuario. En los tests se cambia por una en memoria.
final databaseFactoryProvider = Provider<AppDatabase Function(int userId)>((ref) => AppDatabase.forUser);

/// La base local del usuario. Al cambiar de usuario se cierra y se abre la del otro; si el mismo
/// usuario vuelve a entrar (por ejemplo, tras una sesión expirada), encuentra su cola intacta.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = ref.watch(databaseFactoryProvider)(ref.watch(currentUserIdProvider));
  ref.onDispose(db.close);
  return db;
});

final outboxRepositoryProvider = Provider<OutboxRepository>( // la cola de acciones
    (ref) => OutboxRepository(ref.watch(databaseProvider)));
final settingsStoreProvider = Provider<SettingsStore>( // guarda y lee los parámetros
    (ref) => SettingsStore(ref.watch(databaseProvider)));
final routeStoreProvider = Provider<RouteStore>( // guarda y lee la ruta del día
    (ref) => RouteStore(ref.watch(databaseProvider)));

final mediaRepositoryProvider = Provider<MediaRepository>((ref) { // fotos y videos
  final userId = ref.watch(currentUserIdProvider);
  return MediaRepository(
    ref.watch(databaseProvider),
    baseDir: () => userDirectory(userId), // las fotos van en la carpeta del usuario
  );
});
