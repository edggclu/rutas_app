/// El servidor respondió 401: el token venció o ya no sirve. La cola local no se borra.
class SessionExpiredException implements Exception {
  const SessionExpiredException();
}

/// Después de que expiró la sesión, alguien entró con otra cuenta. Las acciones sin enviar
/// son de [expectedName] y no deben mandarse con otro usuario.
class WrongAccountException implements Exception {
  const WrongAccountException(this.expectedName);

  final String expectedName;
}

/// Al cambiar la contraseña, la actual que se escribió no es la correcta (el servidor responde 422).
class WrongPasswordException implements Exception {
  const WrongPasswordException();
}

/// El código para recuperar la contraseña no es el correcto o ya venció (el servidor responde 422).
class InvalidResetCodeException implements Exception {
  const InvalidResetCodeException();
}
