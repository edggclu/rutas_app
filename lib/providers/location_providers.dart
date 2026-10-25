import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/location_access.dart';
import 'infra_providers.dart';

/// Estado actual del permiso de ubicación. Se vuelve a pedir con `ref.invalidate` cuando la
/// app regresa de los ajustes o después de pedir el permiso.
final locationAccessProvider = FutureProvider.autoDispose<LocationAccess>(
  (ref) => ref.watch(locationServiceProvider).access(),
);
