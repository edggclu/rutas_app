import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:telyser_app/domain/models/app_settings.dart';
import 'package:telyser_app/domain/models/closing_models.dart';
import 'package:telyser_app/domain/models/my_job_models.dart';
import 'package:telyser_app/domain/models/payload.dart';
import 'package:telyser_app/domain/models/product.dart';
import 'package:telyser_app/domain/models/review_models.dart';

import '../../domain/models/models.dart';
import '../repositories.dart';

/// Cambiar a false para volver a los valores reales de assets/mock/settings.json.
const bool kDemoMode = true; // modo demo: la espera de "No me abren" se acorta

Future<Map<String, dynamic>> _loadJson(String asset) async {
  final raw = await rootBundle.loadString(asset);
  return json.decode(raw) as Map<String, dynamic>;
}

/// Usuarios de prueba: usuario (en minúsculas) -> contraseña y archivo de sesión.
const _mockUsers = <String, ({String password, String session})>{ // los usuarios que existen en la demo
  'pedro': (password: 'pedro123', session: 'assets/mock/session_tecnico.json'), // técnico
  'tono': (password: 'tono123', session: 'assets/mock/session_jefe.json'), // técnico + ingeniero + coordina rutas
  'toño': (password: 'tono123', session: 'assets/mock/session_jefe.json'), // el mismo usuario, escrito con ñ
};

/// Solo entran los usuarios de arriba y con su contraseña exacta.
class MockAuthRepository implements AuthRepository { // el login de prueba
  @override
  Future<Session> login(String username, String password) async { // devuelve la sesión o lanza error
    await Future<void>.delayed(const Duration(milliseconds: 400)); // simula la espera de la red
    final user = _mockUsers[username.trim().toLowerCase()]; // busca el usuario (sin importar mayúsculas)
    if (user == null || user.password != password) { // no existe o la contraseña no coincide
      throw Exception('credenciales incorrectas'); // la pantalla muestra "Usuario o contraseña incorrectos"
    }
    final data = await _loadJson(user.session); // lee la sesión de ese usuario
    return Session.fromJson(data); // la convierte en modelo
  }

  @override
  Future<void> logout() async {} // en la versión de prueba no hay nada que avisar al servidor
}

class MockVisitRepository implements VisitRepository { // la ruta de prueba
  MockVisitRepository([this._plans]);

  final MockPlanStore? _plans; // planes que el ingeniero editó en la demo

  @override
  Future<Map<String, dynamic>> fetchMyDay(DateTime date) async { // devuelve el JSON del día
    await Future<void>.delayed(const Duration(milliseconds: 400)); // simula la espera de la red
    final raw = await _loadJson('assets/mock/my_day.json'); // lee el archivo de prueba
    raw['date'] = DateFormat('yyyy-MM-dd').format(date); // la ruta de prueba siempre es "de hoy"
    final saved = _plans?.plans ?? const <int, Plan>{};
    if (saved.isNotEmpty) { // pone en cada trabajo el plan que se editó
      for (final v in readMaps(raw, 'visits')) {
        final job = v['job'];
        if (job is Map && saved.containsKey(job['id'])) job['plan'] = saved[job['id']]!.toJson();
      }
    }
    return raw; // el JSON con la fecha cambiada
  }
}

class MockSettingsRepository implements SettingsRepository { // los parámetros de prueba
  @override
  Future<AppSettings> fetch() async { // devuelve los parámetros
    final map = await _loadJson('assets/mock/settings.json'); // lee el archivo de prueba
    return AppSettings.fromMap({ // los convierte en parámetros
      ...map, // los valores del archivo
      if (kDemoMode) 'wait_base_min': 1, // en la demo, 1 minuto de espera base...
      if (kDemoMode) 'wait_per_km_min': 0, // ...y sin minutos extra por kilómetro
    });
  }
}
/// Catálogo de prueba: lee assets/mock/products.json y filtra por nombre.
class MockProductRepository implements ProductRepository { 
  @override
  Future<List<Product>> search(String query) async { // busca por texto
    final raw = await rootBundle.loadString('assets/mock/products.json'); // lee el archivo de prueba
    final all = (json.decode(raw) as List) // lo convierte en lista
        .map((e) => Product.fromJson(e as Map<String, dynamic>)) 
        .toList();
    final q = query.trim().toLowerCase(); // el texto buscado, sin espacios y en minúsculas
    return all
        .where((p) => p.name.toLowerCase().contains(q)) 
        .take(5) // máximo 5 sugerencias
        .toList();
  }
}
  /// Trabajos por validar de prueba. Los cambios viven en memoria: al cerrar la app, vuelve todo.
class MockReviewRepository implements ReviewRepository {
  List<ReviewJob>? _jobs; // se carga una vez del archivo y luego se modifica

  Future<List<ReviewJob>> _load() async {
    final cached = _jobs;
    if (cached != null) return cached;
    final data = await _loadJson('assets/mock/review.json');
    final loaded = [for (final m in readMaps(data, 'jobs')) ReviewJob.fromJson(m)];
    _jobs = loaded;
    return loaded;
  }

  @override
  Future<List<ReviewJob>> fetchPending() async {
    await Future<void>.delayed(const Duration(milliseconds: 300)); // simula la red
    return List.of(await _load()); // una copia, para que nadie modifique la lista interna
  }

  @override
  Future<void> validate(int jobId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    (await _load()).removeWhere((j) => j.id == jobId); // validado: sale de la lista
  }

  @override
  Future<void> returnJob(int jobId, String note) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    (await _load()).removeWhere((j) => j.id == jobId); // regresado: sale de la lista
  }

  @override
  Future<void> submitVerdict(int jobId, WarrantyCause cause) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final jobs = await _load();
    final i = jobs.indexWhere((j) => j.id == jobId);
    if (i >= 0) jobs[i] = jobs[i].withVerdict(cause); // el trabajo sigue en la lista, ya dictaminado
  }
}


/// Mis trabajos de prueba: lee assets/mock/my_jobs.json.
class MockMyJobsRepository implements MyJobsRepository {
  @override
  Future<List<MyJob>> fetch() async {
    await Future<void>.delayed(const Duration(milliseconds: 300)); // simula la red
    final data = await _loadJson('assets/mock/my_jobs.json');
    return [for (final m in readMaps(data, 'jobs')) MyJob.fromJson(m)];
  }
}


/// Los planes que el ingeniero guardó en la demo. Viven en memoria y los comparten
/// MockPlanRepository (escribe) y MockVisitRepository (los pone en la ruta).
class MockPlanStore {
  final Map<int, Plan> plans = {}; // id del trabajo -> plan guardado
}

/// Guarda el plan en memoria: al cerrar la app por completo vuelve el plan original.
class MockPlanRepository implements PlanRepository {
  MockPlanRepository(this._store);

  final MockPlanStore _store;

  @override
  Future<Plan> save(int jobId, Plan plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 300)); // simula la red
    _store.plans[jobId] = plan;
    return plan;
  }
}
