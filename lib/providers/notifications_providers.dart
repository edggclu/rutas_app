import 'package:flutter_riverpod/flutter_riverpod.dart'; // FutureProvider

import '../domain/models/notification_models.dart'; // AppNotification
import 'infra_providers.dart'; // notificationsRepositoryProvider
import 'session_provider.dart'; // sessionProvider

/// Los avisos del usuario, lo más reciente primero. Se vuelve a pedir al cambiar de sesión
/// o al jalar para actualizar.
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  ref.watch(sessionProvider);
  final list = await ref.watch(notificationsRepositoryProvider).fetch();
  return sortNotifications(list);
});

/// Cuántos avisos faltan por leer (para el punto de la pestaña).
final unreadNoticesProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).value;
  return list == null ? 0 : unreadCount(list);
});

/// Marca avisos como leídos y vuelve a pedir la lista.
final markNoticesReadProvider = Provider<Future<void> Function(List<int> ids)>((ref) => (ids) async {
      await ref.read(notificationsRepositoryProvider).markRead(ids);
      ref.invalidate(notificationsProvider);
      await ref.read(notificationsProvider.future); // espera a que la lista nueva llegue
    });
