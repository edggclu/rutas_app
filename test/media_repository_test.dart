import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/data/local/media/media_repository.dart';

void main() {
  late AppDatabase db; // base en memoria
  late Directory tmp; // carpeta temporal de la prueba
  late MediaRepository repo; // el repositorio
  late File source; // foto "de la cámara" falsa

  setUp(() async { // antes de cada prueba
    db = AppDatabase.forTesting(NativeDatabase.memory()); // base nueva y vacía
    tmp = await Directory.systemTemp.createTemp('telyser_test_'); // carpeta temporal nueva
    repo = MediaRepository( // el repositorio de prueba
      db, // con la base en memoria
      baseDir: () async => tmp, // guarda dentro de la carpeta temporal
      now: () => DateTime.utc(2026, 10, 6, 15), // reloj fijo
    );
    source = File('${tmp.path}/camera.jpg')..writeAsBytesSync([1, 2, 3]); // archivo falso con 3 bytes
  });

  tearDown(() async { // después de cada prueba
    await db.close(); // cierra la base
    await tmp.delete(recursive: true); // borra la carpeta temporal
  });

  test('guarda una copia de la foto y una fila pendiente', () async { // caso principal
    final id = await repo.addPhoto(visitId: 101, sourcePath: source.path); // guarda la foto
    final row = (await db.select(db.mediaQueue).get()).single; // la única fila

    expect(row.uuid, id); // la fila tiene el id devuelto
    expect(row.visitId, 101); // de la visita 101
    expect(row.kind, 'progress'); // tipo avance por defecto
    expect(row.state, 'pending'); // pendiente de subir
    expect(row.wifiOnly, isFalse); // las fotos no esperan Wi-Fi
    expect(row.localPath, isNot(source.path)); // es una copia, no el archivo de la cámara
    expect(File(row.localPath).readAsBytesSync(), [1, 2, 3]); // con el mismo contenido
  });

  test('si la cámara borra su archivo, la copia sigue existiendo', () async { // por eso se copia
    await repo.addPhoto(visitId: 101, sourcePath: source.path); // guarda la foto
    final row = (await db.select(db.mediaQueue).get()).single; // la fila
    source.deleteSync(); // la cámara borra su archivo temporal
    expect(File(row.localPath).existsSync(), isTrue); // la copia sigue ahí
  });

  test('cada visita lista solo sus fotos', () async { // separación por visita
    await repo.addPhoto(visitId: 101, sourcePath: source.path); // foto de la 101
    await repo.addPhoto(visitId: 101, sourcePath: source.path); // otra foto de la 101
    await repo.addPhoto(visitId: 102, sourcePath: source.path); // foto de la 102
    expect((await repo.watchForVisit(101).first).length, 2); // la 101 tiene dos
    expect((await repo.watchForVisit(102).first).length, 1); // la 102 tiene una
  });

  test('un video espera Wi-Fi y conserva su tipo', () async { // los videos pesan mucho
    final clip = File('${tmp.path}/clip.mp4')..writeAsBytesSync([9, 9]); // video falso de 2 bytes
    await repo.addVideo(visitId: 101, sourcePath: clip.path); // guarda el video
    final row = (await db.select(db.mediaQueue).get()).single; // la única fila
    expect(row.kind, 'cabling_video'); // tipo por defecto
    expect(row.wifiOnly, isTrue); // espera Wi-Fi
    expect(row.localPath.endsWith('.mp4'), isTrue); // conserva su extensión
    expect(File(row.localPath).readAsBytesSync(), [9, 9]); // el contenido se copió
  });

  test('borrar quita la fila y el archivo, y deja las demás fotos', () async { // por si se tomó una incorrecta
    final a = await repo.addPhoto(visitId: 101, sourcePath: source.path); // foto que se queda
    final b = await repo.addPhoto(visitId: 101, sourcePath: source.path); // foto incorrecta
    final path = (await repo.watchForVisit(101).first).firstWhere((m) => m.id == b).localPath; // dónde quedó
    await repo.delete(b); // la borra
    final left = await repo.watchForVisit(101).first; // lo que queda
    expect(left.map((m) => m.id), [a]); // solo la buena
    expect(File(path).existsSync(), isFalse); // el archivo también se borró
  });

  test('borrar un video funciona igual', () async {
    final clip = File('${tmp.path}/clip.mp4')..writeAsBytesSync([9, 9]);
    final id = await repo.addVideo(visitId: 101, sourcePath: clip.path);
    await repo.delete(id);
    expect(await repo.watchForVisit(101).first, isEmpty);
  });

  test('borrar algo que ya no existe no falla', () async {
    await repo.delete('no-existe'); // no lanza
  });

  test('si el archivo ya no está, igual se quita la fila', () async {
    final id = await repo.addPhoto(visitId: 101, sourcePath: source.path);
    final row = (await db.select(db.mediaQueue).get()).single;
    File(row.localPath).deleteSync(); // Android lo borró por su cuenta
    await repo.delete(id);
    expect(await db.select(db.mediaQueue).get(), isEmpty);
  });
}
