import 'package:telyser_app/domain/models/app_settings.dart';
import 'package:telyser_app/domain/models/closing_models.dart';
import 'package:telyser_app/domain/models/product.dart';
import 'package:telyser_app/domain/models/review_models.dart';

import '../domain/models/models.dart';

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