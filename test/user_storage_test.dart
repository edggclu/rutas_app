import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/data/local/user_storage.dart';
import 'package:telyser_app/data/repositories.dart';
import 'package:telyser_app/domain/events/event_types.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/models/password_reset.dart';
import 'package:telyser_app/providers/infra_providers.dart';
import 'package:telyser_app/providers/session_provider.dart';
import 'package:telyser_app/providers/storage_providers.dart';

/// Login falso: "pedro" es el usuario 7 y cualquier otro es el 2.
class _FakeAuth implements AuthRepository {
  @override
  Future<Session> login(String username, String password) async => Session(
        token: 't',
        user: AppUser(
          id: username == 'pedro' ? 7 : 2,
          name: username,
          phone: '',
          role: 'technician',
          permissions: const [],
        ),
      );

  @override
  Future<void> logout() async {}

  @override
  Future<void> changePassword(String current, String next) async {}

  @override
  Future<PasswordResetInfo> requestPasswordReset(String login) async => const PasswordResetInfo(codeLength: 6, minLength: 8);

  @override
  Future<void> resetPassword({required String login, required String code, required String newPassword}) async {}
}

void main() {
  test('cada usuario tiene su propia carpeta', () {
    expect(userFolderName(7), p.join('users', '7'));
    expect(userFolderName(2), p.join('users', '2'));
    expect(userFolderName(7), isNot(userFolderName(2)));
  });

  group('lo guardado en el teléfono es del usuario con la sesión', () {
    late List<int> opened; // para qué usuarios se abrió una base
    late ProviderContainer c;

    setUp(() {
      opened = [];
      c = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuth()),
        databaseFactoryProvider.overrideWithValue((userId) {
          opened.add(userId);
          return AppDatabase.forTesting(NativeDatabase.memory()); // una base nueva por usuario
        }),
      ]);
      addTearDown(c.dispose);
    });

    Future<int> queued() async => (await c.read(databaseProvider).select(c.read(databaseProvider).outboxEvents).get()).length;

    test('sin sesión no se toca nada', () {
      bool noSession(Object e) => e.toString().contains('Sin sesión'); // Riverpod envuelve el error
      expect(() => c.read(databaseProvider), throwsA(predicate(noSession)));
      expect(() => c.read(outboxRepositoryProvider), throwsA(predicate(noSession)));
      expect(opened, isEmpty);
    });

    test('al entrar se abre la base de ese usuario', () async {
      await c.read(sessionProvider.notifier).login('pedro', 'x');
      c.read(databaseProvider);
      expect(opened, [7]);
    });

    test('otro usuario en el mismo teléfono no ve la cola del primero', () async {
      final session = c.read(sessionProvider.notifier);
      await session.login('pedro', 'x');
      await c.read(outboxRepositoryProvider).enqueue(
            type: EventTypes.arrived,
            graceSeconds: 0,
            visitId: 101,
            payload: const {},
          );
      expect(await queued(), 1); // Pedro tiene una acción sin enviar

      await session.logout();
      await session.login('tono', 'x');
      expect(await queued(), 0); // Toño no ve la de Pedro
      expect(opened, [7, 2]); // se abrió la base de cada uno
    });

    test('si el mismo usuario vuelve a entrar tras expirar, sigue con su base', () async {
      final session = c.read(sessionProvider.notifier);
      await session.login('pedro', 'x');
      c.read(databaseProvider);
      session.expire(); // la sesión expiró: no se borra nada
      expect(c.read(expiredUserProvider)!.id, 7);
      await session.login('pedro', 'x');
      c.read(databaseProvider);
      expect(opened, [7]); // no hay por qué abrir otra: es la misma base, con su cola intacta
    });
  });
}
