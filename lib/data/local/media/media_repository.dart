import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:telyser_app/data/local/app_database.dart';
import 'package:uuid/uuid.dart';
import 'package:telyser_app/domain/models/media_item.dart';

/// Fotos y videos de las visitas. Guarda el archivo en una carpeta propia de la
/// app y deja una fila en `media_queue` para subirlo cuando haya señal (paso 8).
class MediaRepository { // aquí vive todo lo relacionado con fotos y videos guardados
  MediaRepository( // constructor
    this._db, { // la base de datos local
    required Future<Directory> Function() baseDir, // función que da la carpeta donde guardar (se cambia en tests)
    DateTime Function()? now, // reloj opcional (se cambia en tests)
    Uuid? uuid, // generador de ids opcional
  })  : _baseDir = baseDir, // guarda la función de carpeta
        _now = now ?? (() => DateTime.now().toUtc()), // si no hay reloj, usa la hora real en UTC
        _uuid = uuid ?? const Uuid(); // si no hay generador, usa el normal

  final AppDatabase _db; // la base local
  final Future<Directory> Function() _baseDir; // cómo obtener la carpeta base
  final DateTime Function() _now; // cómo obtener la hora actual
  final Uuid _uuid; // el generador de ids

  /// Foto: se sube apenas haya señal.
  Future<String> addPhoto({ // devuelve el id de la foto
    required int visitId, // a qué visita pertenece
    required String sourcePath, // dónde dejó la foto la cámara (carpeta temporal)
    MediaKind kind = MediaKind.progress, // tipo de foto
  }) =>
      _addFile( // usa el método compartido
        visitId: visitId, // visita
        sourcePath: sourcePath, // archivo de la cámara
        kind: kind, // tipo
        wifiOnly: false, // las fotos pesan poco: no esperan Wi-Fi
        defaultExt: '.jpg', // extensión si el archivo no trae una
      );

  /// Video: pesa mucho, así que espera Wi-Fi (o a que el técnico decida).
  Future<String> addVideo({ // devuelve el id del video
    required int visitId, // a qué visita pertenece
    required String sourcePath, // dónde dejó el video la cámara
    MediaKind kind = MediaKind.cablingVideo, // tipo: video del cableado
  }) =>
      _addFile( // usa el método compartido
        visitId: visitId, // visita
        sourcePath: sourcePath, // archivo de la cámara
        kind: kind, // tipo
        wifiOnly: true, // espera Wi-Fi para subirse
        defaultExt: '.mp4', // extensión si el archivo no trae una
      );

  /// Copia el archivo a la carpeta de la app y lo deja pendiente de subir.
  Future<String> _addFile({ // lo que tienen en común fotos y videos
    required int visitId, // visita
    required String sourcePath, // archivo de origen
    required MediaKind kind, // tipo
    required bool wifiOnly, // ¿espera Wi-Fi?
    required String defaultExt, // extensión por defecto
  }) async {
    final id = _uuid.v4(); // id único de este archivo
    final root = await _baseDir(); // carpeta base de la app
    final dir = Directory(p.join(root.path, 'media', 'visit_$visitId')); // una subcarpeta por visita
    await dir.create(recursive: true); // la crea si no existe
    final ext = p.extension(sourcePath); // extensión del archivo original (ej. ".jpg")
    final target = p.join(dir.path, '$id${ext.isEmpty ? defaultExt : ext}'); // ruta final con el id como nombre
    await File(sourcePath).copy(target); // copia el archivo de la cámara a la ruta final
    await _db.into(_db.mediaQueue).insert( // guarda la fila en la base
          MediaQueueCompanion.insert( // datos de la fila
            uuid: id, // id del archivo
            visitId: visitId, // visita
            kind: kind.code, // la base guarda el código de texto
            localPath: target, // dónde quedó guardado
            wifiOnly: Value(wifiOnly), // si espera Wi-Fi
            createdAtUtc: _now(), // hora en que se tomó (UTC)
          ),
        );
    return id; // devuelve el id
  }

  /// Archivos de una visita, en el orden en que se tomaron. Se vuelve a emitir
  /// cada vez que cambia la tabla. Devuelve `MediaItem`: las filas de Drift no salen de `data/`.
  Stream<List<MediaItem>> watchForVisit(int visitId) => // flujo de listas
      (_db.select(_db.mediaQueue) // consulta la tabla
            ..where((m) => m.visitId.equals(visitId)) // solo los de esta visita
            ..orderBy([(m) => OrderingTerm.asc(m.createdAtUtc)])) // de más antiguo a más nuevo
          .watch() // escucha cambios en vez de leer una sola vez
          .map((rows) { // convierte cada lista de filas en MediaItem
        final items = <MediaItem>[]; // aquí se juntan
        for (final r in rows) { // por cada fila
          final kind = MediaKind.tryFromCode(r.kind); // el tipo guardado
          if (kind == null) continue; // si el código no se reconoce, se omite (no ensucia los contadores)
          items.add(MediaItem( // arma el modelo de dominio
            id: r.uuid, // id
            kind: kind, // tipo
            localPath: r.localPath, // ruta
            sent: r.state == 'sent', // ¿ya se subió?
          ));
        }
        return items; // la lista convertida
  });
  
    /// Borra todas las fotos y videos guardados (filas y archivos). Solo para reiniciar la demo.
  Future<void> clearAll() async { // no devuelve nada
    final rows = await _db.select(_db.mediaQueue).get(); // primero se leen, para saber qué archivos borrar
    await _db.delete(_db.mediaQueue).go(); // borra todas las filas
    for (final r in rows) { // por cada archivo que había
      try { // si uno falla, se sigue con el siguiente
        final f = File(r.localPath); // el archivo en el teléfono
        if (await f.exists()) await f.delete(); // lo borra si existe
      } catch (_) {} // se ignora el error
    }
  }
}