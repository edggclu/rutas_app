import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:telyser_app/domain/models/app_settings.dart';
import 'package:telyser_app/domain/models/product.dart';

import '../../domain/models/models.dart';
import '../repositories.dart';

/// Cambiar a false para volver a los valores reales de assets/mock/settings.json.
const bool kDemoMode = true; // modo demo: la espera de "No me abren" se acorta

Future<Map<String, dynamic>> _loadJson(String asset) async {
  final raw = await rootBundle.loadString(asset);
  return json.decode(raw) as Map<String, dynamic>;
}

/// Acepta cualquier contraseña. Usuario "tono" o "jefe" entra como Toño
/// (técnico + ingeniero + coordina rutas); cualquier otro entra como Pedro.
class MockAuthRepository implements AuthRepository {
  @override
  Future<Session> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final u = username.trim().toLowerCase();
    if (u.isEmpty || password.isEmpty) {
      throw Exception('credenciales vacías');
    }
    final isBoss = u == 'tono' || u == 'toño' || u == 'jefe';
    final data = await _loadJson(
      isBoss ? 'assets/mock/session_jefe.json' : 'assets/mock/session_tecnico.json',
    );
    return Session.fromJson(data);
  }

  @override
  Future<void> logout() async {}
}

class MockVisitRepository implements VisitRepository { // la ruta de prueba

  @override
  Future<Map<String, dynamic>> fetchMyDay(DateTime date) async { // devuelve el JSON del día
    await Future<void>.delayed(const Duration(milliseconds: 400)); // simula la espera de la red
    final raw = await _loadJson('assets/mock/my_day.json'); // lee el archivo de prueba
    raw['date'] = DateFormat('yyyy-MM-dd').format(date); // la ruta de prueba siempre es "de hoy"
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