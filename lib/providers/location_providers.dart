import 'package:flutter_riverpod/flutter_riverpod.dart'; // FutureProvider

import '../domain/models/location_access.dart'; // LocationAccess
import 'infra_providers.dart'; // locationServiceProvider

/// Estado actual del permiso de ubicación. Se vuelve a pedir con `ref.invalidate` cuando la
/// app regresa de los ajustes o después de pedir el permiso.
final locationAccessProvider = FutureProvider.autoDispose<LocationAccess>(
  (ref) => ref.watch(locationServiceProvider).access(),
);
