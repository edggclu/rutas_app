import 'package:telyser_app/domain/app_settings.dart';

import '../domain/models.dart';

/// Las pantallas nunca hablan con la API: usan estas interfaces. Hoy se
/// implementan con datos de prueba (lib/data/mock); cuando exista la API de
/// Laravel se agrega una implementación HTTP y se cambia en providers.dart.

abstract class AuthRepository {
  Future<Session> login(String username, String password);
  Future<void> logout();
}

abstract class VisitRepository {
  // Future<DayRoute> myDay(DateTime date);
  Future<Map<String,dynamic>> fetchMyDay(DateTime date);
}

abstract class SettingsRepository {
  Future<AppSettings> fetch();
}