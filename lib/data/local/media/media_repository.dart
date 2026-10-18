import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:telyser_app/data/local/app_database.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

/// Fotos y videos de las visitas. Guarda el archivo en una carpeta propia de la
/// app y deja una fila en `media_queue` para subirlo cuando haya señal
class MediaRepository { 

  // aquí vive todo lo relacionado con fotos guardadas
  MediaRepository( 
    this._db, { // la base de datos local
    required Future<Directory> Function() baseDir, // función que da la carpeta donde guardar, se cambia en tests
    DateTime Function()? now, // reloj opcional
    Uuid? uuid, // generador de ids
  })  : _baseDir = baseDir, // guarda la función de carpeta
        _now = now ?? (() => DateTime.now().toUtc()), // si no hay reloj, usa la hora real en UTC
        _uuid = uuid ?? const Uuid(); // si no hay generador, usa el normal

  final AppDatabase _db; 
  final Future<Directory> Function() _baseDir; 
  final DateTime Function() _now; 
  final Uuid _uuid; 

  /// Copia la foto a la carpeta de la app y la deja pendiente de subir
  Future<String> addPhoto({ 
    required int visitId, // a qué visita pertenece
    required String sourcePath, // dónde dejo la foto la camara, carpeta temporal
    String kind = 'progress', // tipo: avance, garantía, daño, cierre
  }) async {
    final id = _uuid.v4(); // id único de esta foto
    final root = await _baseDir(); // carpeta base de la app
    final dir = Directory(p.join(root.path, 'media', 'visit_$visitId')); // una subcarpeta por visita
    await dir.create(recursive: true); // la crea si no existe
    final target = p.join(dir.path, '$id.jpg'); // ruta final de la foto
    await File(sourcePath).copy(target); // copia el archivo de la cámara a la ruta final
    await _db.into(_db.mediaQueue).insert( // guarda la fila en la base
          MediaQueueCompanion.insert( 
            uuid: id, // id de la foto
            visitId: visitId, // visita
            kind: kind, // tipo de foto
            localPath: target, // dónde quedó guardada
            createdAtUtc: _now(), // hora en que se tomo, utc
          ),
        );
    return id; // devuelve el id
  }

  /// Fotos de una visita, en el orden en que se tomaron. Se vuelve a emitir
  /// cada vez que cambia la tabla - foto nueva, foto subida
  Stream<List<MediaQueueData>> watchForVisit(int visitId) => // flujo de listas de fotos
      (_db.select(_db.mediaQueue) // consulta la tabla de fotos
            ..where((m) => m.visitId.equals(visitId)) // solo las de esta visita
            ..orderBy([(m) => OrderingTerm.asc(m.createdAtUtc)])) // de la más antigua a la más nueva
          .watch(); // escucha cambios en vez de leer una sola vez
}