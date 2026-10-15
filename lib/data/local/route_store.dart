import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/domain/models.dart';

/// Caché de "mi día": una fila por visita, con el JSON completo tal como llegó.
class RouteStore {
  RouteStore(this._db);
  final AppDatabase _db;

  /// Recibe el JSON crudo de GET /api/my-day. Solo se guarda el día vigente.
  Future<void> saveDay(Map<String, dynamic> raw) async {
    final date = raw['date'] as String;
    final visits = ((raw['visits'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();

    await _db.transaction(() async {
      await _db.delete(_db.cachedVisits).go();
      await _db.batch((b) {
        b.insertAll(_db.cachedVisits, [
          for (final v in visits)
            CachedVisitsCompanion.insert(
              id: Value(v['id'] as int),
              date: date,
              orderInRoute: v['order'] as int,
              status: v['status'] as String,
              result: Value(v['result'] as String?),
              json: jsonEncode(v),
              arrivedAtUtc: Value(v['arrived_at'] == null
                ? null
                : DateTime.parse(v['arrived_at'] as String).toUtc()
              ),
            )
        ]);
      });
    });
  }

  /// null si no hay nada guardado para esa fecha (formato YYYY-MM-DD).
  Future<DayRoute?> loadDay(String date) async {
    final rows = await (_db.select(_db.cachedVisits)
      ..where((v) => v.date.equals(date))
      ..orderBy([(v) => OrderingTerm.asc(v.orderInRoute)])
    ).get();
    if(rows.isEmpty) return null;
    return DayRoute.fromJson({
      'date': date,
      'visits': [for (final r in rows) jsonDecode(r.json)],
    });
  }

}