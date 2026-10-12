import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Parámetros descargados de /api/settings (clave, valor).
class SettingsKv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

/// Una fila por visita descargada; el detalle completo va como JSON.
class CachedVisits extends Table {
  IntColumn get id => integer()();
  TextColumn get date => text()(); // YYYY-MM-DD
  IntColumn get orderInRoute => integer()();
  TextColumn get status => text()(); // pending | en_route | on_site | done
  TextColumn get result => text().nullable()();
  TextColumn get json => text()();
  DateTimeColumn get arrivedAtUtc => dateTime().nullable()();
  RealColumn get arrivalLat => real().nullable()();
  RealColumn get arrivalLng => real().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// COLA de acciones (outbox).
/// Estados: grace (10 s para deshacer, no enviable) -> pending -> sending -> failed.
class OutboxEvents extends Table {
  TextColumn get uuid => text()();
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get type => text()();
  IntColumn get visitId => integer().nullable()();
  DateTimeColumn get occurredAtUtc => dateTime()();
  TextColumn get tz =>
      text().withDefault(const Constant('America/Mexico_City'))();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  TextColumn get state => text().withDefault(const Constant('pending'))();
  DateTimeColumn get graceUntilUtc => dateTime().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

/// Fotos y videos pendientes de subir.
class MediaQueue extends Table {
  TextColumn get uuid => text()();
  IntColumn get visitId => integer()();
  TextColumn get kind => text()();
  TextColumn get localPath => text()();
  BoolColumn get wifiOnly => boolean().withDefault(const Constant(false))();
  TextColumn get state => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAtUtc => dateTime()();
  @override
  Set<Column> get primaryKey => {uuid};
}

@DriftDatabase(tables: [SettingsKv, CachedVisits, OutboxEvents, MediaQueue])
class AppDatabase extends _$AppDatabase {
  /// Base real: un archivo SQLite dentro del teléfono.
  AppDatabase() : super(_openConnection());

  /// Para tests: base en memoria, sin archivo.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
      File(p.join(dir.path, 'telyser.sqlite')),
    );
  });
}