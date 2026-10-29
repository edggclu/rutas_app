import 'package:telyser_app/domain/models/app_settings.dart';
import 'package:telyser_app/domain/models/dispatch_models.dart';
import 'package:telyser_app/domain/models/closing_models.dart';
import 'package:telyser_app/domain/models/my_job_models.dart';
import 'package:telyser_app/domain/models/password_reset.dart';
import 'package:telyser_app/domain/models/notification_models.dart';
import 'package:telyser_app/domain/models/geo_point.dart';
import 'package:telyser_app/domain/models/product.dart';
import 'package:telyser_app/domain/models/route_path.dart';
import 'package:telyser_app/domain/models/review_models.dart';

import '../domain/models/models.dart';

/// Las pantallas nunca hablan con la API: usan estas interfaces. Hoy se
/// implementan con datos de prueba (lib/data/mock); cuando exista la API de
/// Laravel se agrega una implementación HTTP y se cambia en providers.dart.

abstract class AuthRepository {
  Future<Session> login(String username, String password);
  Future<void> logout();
  Future<void> changePassword(String current, String next); // lanza WrongPasswordException si la actual no es correcta
  Future<PasswordResetInfo> requestPasswordReset(String login); // manda un código al teléfono registrado (siempre responde igual: no dice si el usuario existe)
  Future<void> resetPassword({required String login, required String code, required String newPassword}); // lanza InvalidResetCodeException si el código falla
}

abstract class VisitRepository {
  // Future<DayRoute> myDay(DateTime date);
  Future<Map<String,dynamic>> fetchMyDay(DateTime date);
}

abstract class SettingsRepository {
  Future<AppSettings> fetch();
}

abstract class ProductRepository {
  Future<List<Product>> search(String query); // devuelve los productos cuyo nombre coincide
}

/// Trabajos terminados por validar. Todo necesita señal: no pasa por la cola.
abstract class ReviewRepository {
  Future<List<ReviewJob>> fetchPending(); // los trabajos que esperan validación
  Future<void> validate(int jobId); // lo da por bueno
  Future<void> returnJob(int jobId, String note); // lo regresa con una nota
  Future<void> submitVerdict(int jobId, WarrantyCause cause); // dictamen de la causa de una garantía
}

/// Los trabajos que el técnico ya terminó y lo que el ingeniero decidió de ellos.
abstract class MyJobsRepository {
  Future<List<MyJob>> fetch();
}


/// El plan del trabajo que edita el ingeniero. Necesita señal: no pasa por la cola.
abstract class PlanRepository {
  Future<Plan> save(int jobId, Plan plan); // guarda y devuelve el plan tal como quedó en el servidor
}


/// Avisos del usuario. Necesita señal: no pasa por la cola.
abstract class NotificationsRepository {
  Future<List<AppNotification>> fetch();
  Future<void> markRead(List<int> ids); // los marca como leídos en el servidor
}


/// Lo que ve el jefe de ruta. Necesita señal: no pasa por la cola. La implementación de la API
/// arma el tablero con `dispatch/decisions`, `dispatch/today` (hoy y mañana) y `dispatch/unassigned`.
abstract class DispatchRepository {
  Future<DispatchBoard> fetch();
}


/// La ruta por calles entre varios puntos. Necesita señal; si no se puede, devuelve null y la
/// app dibuja la línea recta.
abstract class RoutingRepository {
  Future<RoutePath?> route(List<GeoPoint> stops);
}
