import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:telyser_app/domain/app_settings.dart';
import 'package:telyser_app/domain/product.dart';

import '../../domain/models.dart';
import '../repositories.dart';

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

class MockVisitRepository implements VisitRepository {
  @override
  Future<Map<String, dynamic>> fetchMyDay(DateTime date) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _loadJson('assets/mock/my_day.json');
  }
}
class MockSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> fetch() async =>
      AppSettings.fromMap(await _loadJson('assets/mock/settings.json'));
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