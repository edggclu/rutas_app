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
