import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/data/local/outbox_repository.dart';

void main(){

  late AppDatabase db;
  late OutboxRepository repo;
  late DateTime now;

  setUp(() {
    now = DateTime.utc(2026,10,6,14,20);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = OutboxRepository(db, now: () => now);
  });

  tearDown(() => db.close());

  test('Una accion nueva queda en tiempo de gracia y no se pudo enviar', () async {
    await repo.enqueue(type: 'arrive', graceSeconds: 10, visitId: 101);
    expect(await repo.nextBatch(), isEmpty);
  });

  test("Deshacer antes de los 10s la borra ", () async {
    final id = await repo.enqueue(type: 'arrived', graceSeconds: 10);
    now = now.add(const Duration(seconds: 7));
    expect(await repo.undo(id), isTrue);
    now = now.add(const Duration(seconds: 10));
    await repo.releaseExpired();
    expect(await repo.nextBatch(), isEmpty);
  });

  test('pasalos los 10s ya no se puede deshacer y se libera', () async {
    final id = await repo.enqueue(type: 'arrived', graceSeconds: 10);
    now = now.add(const Duration(seconds: 11));
    expect(await repo.undo(id), isFalse);
    expect(await repo.releaseExpired(), 1);
    expect(await repo.nextBatch(), hasLength(1));
  });

  test('El orden se respeta: no se envia una accion antes que la anterior', () async {
    final a = await repo.enqueue(type: 'arrived', graceSeconds: 10);
    now = now.add(const Duration(seconds: 5));
    final b = await repo.enqueue(type: 'finished', graceSeconds: 10);
    
    now = now.add(const Duration(seconds: 6)); // 5+6=11 se libera a, pero b sigue en tiempo de gracia
    await repo.releaseExpired();
    expect((await repo.nextBatch()).map((e) => e.uuid), [a]);

    now = now.add(const Duration(seconds: 5));
    await repo.releaseExpired();
    expect((await repo.nextBatch()).map((e) => e.uuid), [a, b]);

  });

}
