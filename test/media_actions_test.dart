import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/application/media_actions.dart';
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/data/local/media/media_repository.dart';
import 'package:telyser_app/domain/media_rules.dart';
import 'package:telyser_app/domain/models/media_item.dart';

void main() {
  late AppDatabase db;
  late Directory tmp;
  late MediaRepository repo;
  late MediaActions actions;
  late File source;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tmp = await Directory.systemTemp.createTemp('telyser_test_');
    repo = MediaRepository(db, baseDir: () async => tmp);
    actions = MediaActions(repo);
    source = File('${tmp.path}/camera.jpg')..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  MediaItem item({required bool sent}) =>
      MediaItem(id: 'x', kind: MediaKind.progress, localPath: 'x.jpg', sent: sent);

  test('solo se borra lo que todavía no se sube', () {
    expect(canDeleteMedia(item(sent: false)), isTrue);
    expect(canDeleteMedia(item(sent: true)), isFalse);
  });

  test('el video también es de un tipo distinto al de las fotos', () {
    expect(MediaKind.cablingVideo.isVideo, isTrue);
    expect(MediaKind.progress.isVideo, isFalse);
    expect(MediaKind.warranty.isVideo, isFalse);
  });

  test('borrar una foto pendiente la quita', () async {
    await repo.addPhoto(visitId: 101, sourcePath: source.path);
    final photo = (await repo.watchForVisit(101).first).single;
    await actions.delete(photo);
    expect(await repo.watchForVisit(101).first, isEmpty);
  });

  test('una foto ya subida no se borra ni se toca el archivo', () async {
    final id = await repo.addPhoto(visitId: 101, sourcePath: source.path);
    await (db.update(db.mediaQueue)..where((m) => m.uuid.equals(id)))
        .write(const MediaQueueCompanion(state: Value('sent'))); // el servidor ya la tiene
    final photo = (await repo.watchForVisit(101).first).single;
    expect(photo.sent, isTrue);
    await expectLater(actions.delete(photo), throwsStateError);
    expect(File(photo.localPath).existsSync(), isTrue);
    expect(await repo.watchForVisit(101).first, hasLength(1));
  });
}
