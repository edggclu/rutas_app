import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/data/repositories.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/session_errors.dart';
import 'package:telyser_app/providers/infra_providers.dart';
import 'package:telyser_app/providers/session_provider.dart';

/// Login falso: el usuario "pedro" es el 7 y cualquier otro es el 2.
class _FakeAuth implements AuthRepository {
  int logouts = 0;

  @override
  Future<Session> login(String username, String password) async => Session(
        token: 't-$username',
        user: AppUser(
          id: username == 'pedro' ? 7 : 2,
          name: username == 'pedro' ? 'Pedro' : 'Toño',
          phone: '',
          role: 'technician',
          permissions: const [],
        ),
      );

  @override
  Future<void> logout() async => logouts++;
}

void main() {
  late _FakeAuth auth;
  late ProviderContainer c;

  setUp(() {
    auth = _FakeAuth();
    c = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(auth)]);
    addTearDown(c.dispose);
  });

  test('al expirar se sale de la sesión y se recuerda quién era', () async {
    await c.read(sessionProvider.notifier).login('pedro', 'x');
    c.read(sessionProvider.notifier).expire();
    expect(c.read(sessionProvider), isNull);
    expect(c.read(expiredUserProvider)!.id, 7);
    expect(auth.logouts, 0); // el token ya no sirve: no se le avisa al servidor
  });

  test('el mismo usuario puede volver a entrar y el aviso desaparece', () async {
    final s = c.read(sessionProvider.notifier);
    await s.login('pedro', 'x');
    s.expire();
    await s.login('pedro', 'x');
    expect(c.read(sessionProvider)!.user.id, 7);
    expect(c.read(expiredUserProvider), isNull);
  });

  test('otra cuenta no entra: las acciones sin enviar son de la anterior', () async {
    final s = c.read(sessionProvider.notifier);
    await s.login('pedro', 'x');
    s.expire();
    await expectLater(s.login('tono', 'x'), throwsA(isA<WrongAccountException>()));
    expect(c.read(sessionProvider), isNull);
    expect(c.read(expiredUserProvider)!.id, 7); // sigue esperando a Pedro
    expect(auth.logouts, 1); // se cerró la sesión que se abrió por error
  });

  test('cerrar sesión a propósito no cuenta como expirar', () async {
    final s = c.read(sessionProvider.notifier);
    await s.login('pedro', 'x');
    await s.logout();
    expect(c.read(expiredUserProvider), isNull);
    await s.login('tono', 'x'); // cualquier cuenta puede entrar
    expect(c.read(sessionProvider)!.user.id, 2);
  });

  test('expirar sin sesión no hace nada', () {
    c.read(sessionProvider.notifier).expire();
    expect(c.read(expiredUserProvider), isNull);
  });
}
