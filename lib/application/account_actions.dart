import '../data/repositories.dart';
import '../domain/models/password_reset.dart';
import '../domain/password_rules.dart';

/// Acciones de la cuenta del usuario. Necesitan señal: van directo al servidor, no por la cola.
class AccountActions {
  AccountActions(this._auth);

  final AuthRepository _auth;

  /// Cambia la contraseña. Lanza [ArgumentError] si no cumple las reglas (la pantalla ya lo
  /// avisa antes) y `WrongPasswordException` si la actual no es correcta.
  Future<void> changePassword({
    required String current,
    required String next,
    required String confirm,
    required int minLength,
  }) async {
    final issue = checkNewPassword(current: current, next: next, confirm: confirm, minLength: minLength);
    if (issue != null) throw ArgumentError(issue.name);
    await _auth.changePassword(current, next);
  }

  /// Pide el código para recuperar la contraseña (sin sesión). Siempre responde igual, exista o no
  /// el usuario, para no revelar quién tiene cuenta.
  Future<PasswordResetInfo> requestReset(String login) {
    if (login.trim().isEmpty) throw ArgumentError('Falta el usuario o teléfono');
    return _auth.requestPasswordReset(login.trim());
  }

  /// Fija la contraseña nueva con el código. Lanza [ArgumentError] si no cumple las reglas y
  /// `InvalidResetCodeException` si el código no es el correcto o ya venció.
  Future<void> resetPassword({
    required String login,
    required String code,
    required String next,
    required String confirm,
    required PasswordResetInfo info,
  }) async {
    final issue = checkResetPassword(
      code: code,
      next: next,
      confirm: confirm,
      codeLength: info.codeLength,
      minLength: info.minLength,
    );
    if (issue != null) throw ArgumentError(issue.name);
    await _auth.resetPassword(login: login.trim(), code: code, newPassword: next);
  }
}
