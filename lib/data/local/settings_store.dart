import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/app_settings.dart';
import 'app_database.dart';

/// Guarda los parámetros en la tabla SettingsKv (clave, valor).
class SettingsStore {
  SettingsStore(this._db);
  final AppDatabase _db;

  Future<void> save(AppSettings s) async {
    await _db.batch((b) {
      b.insertAll(
        _db.settingsKv,
        [
          for (final e in s.toMap().entries)
            SettingsKvCompanion.insert(key: e.key, value: jsonEncode(e.value)),
        ],
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// null si nunca se han descargado o están incompletos.
  Future<AppSettings?> load() async {
    final rows = await _db.select(_db.settingsKv).get();
    if (rows.isEmpty) return null;
    final map = {for (final r in rows) r.key: jsonDecode(r.value)};
    try {
      return AppSettings.fromMap(map);
    } catch (_) {
      return null;
    }
  }
}