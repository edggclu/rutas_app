import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

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
  Future<DayRoute> myDay(DateTime date) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return DayRoute.fromJson(await _loadJson('assets/mock/my_day.json'));
  }
}
