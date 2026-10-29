import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/application/account_actions.dart';
import 'package:telyser_app/data/mock/mock_repositories.dart';
import 'package:telyser_app/data/repositories.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/models/password_reset.dart';
import 'package:telyser_app/domain/password_rules.dart';
import 'package:telyser_app/domain/session_errors.dart';

/// Repositorio falso: anota lo que se le pidió.
class _FakeAuth implements AuthRepository {
  final changes = <String>[];
  final resets = <String>[];

  @override
  Future<Session> login(String username, String password) => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<void> changePassword(String current, String next) async => changes.add('$current>$next');
@override  Future<PasswordResetInfo> requestPasswordReset(String login) async => const PasswordResetInfo(codeLength: 6, minLength: 8);  @override  Future<void> resetPassword({required String login, required String code, required String newPassword}) async =>
      resets.add('$login:$code>$newPassword');
}

PasswordIssue? _check({String current = 'vieja123', String next = 'nueva1234', String confirm = 'nueva1234'}) =>
    checkNewPassword(current: current, next: next, confirm: confirm, minLength: 8);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // el mock lee assets/

  group('reglas', () {
    test('una contraseña nueva correcta no tiene problemas', () => expect(_check(), isNull));
    test('faltan campos', () {
      expect(_check(current: ''), PasswordIssue.empty);
      expect(_check(next: ''), PasswordIssue.empty);
      expect(_check(confirm: ''), PasswordIssue.empty);
    });
    test('muy corta', () => expect(_check(next: 'corta', confirm: 'corta'), PasswordIssue.tooShort));
    test('igual a la actual', () => expect(_check(next: 'vieja123', confirm: 'vieja123'), PasswordIssue.sameAsCurrent));
    test('no coinciden', () => expect(_check(confirm: 'otra12345'), PasswordIssue.mismatch));
    test('el largo mínimo viene de los parámetros', () {
      expect(checkNewPassword(current: 'a', next: 'abcdefgh', confirm: 'abcdefgh', minLength: 12), PasswordIssue.tooShort);
    });
  });

  group('acción', () {
    test('manda la contraseña al servidor', () async {
      final repo = _FakeAuth();
      await AccountActions(repo).changePassword(current: 'vieja123', next: 'nueva1234', confirm: 'nueva1234', minLength: 8);
      expect(repo.changes, ['vieja123>nueva1234']);
    });

    test('una contraseña inválida no llega al servidor', () async {
      final repo = _FakeAuth();
      await expectLater(
        AccountActions(repo).changePassword(current: 'vieja123', next: 'corta', confirm: 'corta', minLength: 8),
        throwsArgumentError,
      );
      expect(repo.changes, isEmpty);
    });
  });

  group('repositorio de prueba', () {
    test('cambiar la contraseña hace que la nueva funcione y la vieja no', () async {
      final auth = MockAuthRepository();
      await auth.login('pedro', 'pedro123');
      await auth.changePassword('pedro123', 'nueva1234');
      await expectLater(auth.login('pedro', 'pedro123'), throwsException);
      expect((await auth.login('pedro', 'nueva1234')).user.name, 'Pedro');
    });

    test('con la contraseña actual equivocada se rechaza y no cambia nada', () async {
      final auth = MockAuthRepository();
      await auth.login('pedro', 'pedro123');
      await expectLater(auth.changePassword('mal', 'nueva1234'), throwsA(isA<WrongPasswordException>()));
      expect((await auth.login('pedro', 'pedro123')).user.name, 'Pedro');
    });

    test('sin sesión abierta no se puede cambiar', () async {
      await expectLater(MockAuthRepository().changePassword('a', 'b'), throwsA(isA<SessionExpiredException>()));
    });
  });

  group('recuperar la contraseña (sin sesión)', () {
    PasswordIssue? check({String code = '123456', String next = 'nueva1234', String confirm = 'nueva1234'}) =>
        checkResetPassword(code: code, next: next, confirm: confirm, codeLength: 6, minLength: 8);

    test('con el código y la contraseña bien, no hay problemas', () => expect(check(), isNull));
    test('faltan campos', () {
      expect(check(code: ''), PasswordIssue.empty);
      expect(check(next: ''), PasswordIssue.empty);
      expect(check(confirm: ''), PasswordIssue.empty);
    });
    test('el código debe tener el largo que dice el servidor', () => expect(check(code: '123'), PasswordIssue.badCode));
    test('contraseña corta o que no coincide', () {
      expect(check(next: 'corta', confirm: 'corta'), PasswordIssue.tooShort);
      expect(check(confirm: 'otra12345'), PasswordIssue.mismatch);
    });

    test('pedir el código sin escribir el usuario no llega al servidor', () {
      expect(() => AccountActions(_FakeAuth()).requestReset('  '), throwsArgumentError);
    });

    test('la acción manda el usuario sin espacios, el código y la contraseña', () async {
      final repo = _FakeAuth();
      const info = PasswordResetInfo(codeLength: 6, minLength: 8);
      await AccountActions(repo).resetPassword(
          login: ' pedro ', code: '123456', next: 'nueva1234', confirm: 'nueva1234', info: info);
      expect(repo.resets, ['pedro:123456>nueva1234']);
    });

    test('una contraseña inválida no llega al servidor', () async {
      final repo = _FakeAuth();
      const info = PasswordResetInfo(codeLength: 6, minLength: 8);
      await expectLater(
        AccountActions(repo).resetPassword(login: 'pedro', code: '12', next: 'nueva1234', confirm: 'nueva1234', info: info),
        throwsArgumentError,
      );
      expect(repo.resets, isEmpty);
    });

    test('en la demo, el código correcto cambia la contraseña y el incorrecto no', () async {
      final auth = MockAuthRepository();
      final info = await auth.requestPasswordReset('pedro');
      expect(info.codeLength, 6);
      expect(info.minLength, 8); // sale de settings.json
      await expectLater(
        auth.resetPassword(login: 'pedro', code: '000000', newPassword: 'nueva1234'),
        throwsA(isA<InvalidResetCodeException>()),
      );
      await auth.resetPassword(login: 'pedro', code: MockAuthRepository.demoResetCode, newPassword: 'nueva1234');
      expect((await auth.login('pedro', 'nueva1234')).user.name, 'Pedro');
      await expectLater(auth.login('pedro', 'pedro123'), throwsException);
    });

    test('un usuario que no existe recibe el mismo error que un código malo', () async {
      await expectLater(
        MockAuthRepository().resetPassword(login: 'nadie', code: MockAuthRepository.demoResetCode, newPassword: 'nueva1234'),
        throwsA(isA<InvalidResetCodeException>()),
      );
    });
  });
}
