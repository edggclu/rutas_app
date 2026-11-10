import 'package:flutter_riverpod/flutter_riverpod.dart';

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


final dispatchRepositoryProvider = // el tablero del jefe de ruta
    Provider<DispatchRepository>((ref) => MockDispatchRepository()); // hoy, el de prueba
