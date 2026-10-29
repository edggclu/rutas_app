/// Qué está mal al escribir una contraseña nueva. null en las funciones de abajo = todo bien.
enum PasswordIssue { empty, tooShort, sameAsCurrent, mismatch, badCode }

/// Las reglas comunes de una contraseña nueva: largo mínimo y que se escriba igual dos veces.
PasswordIssue? _checkNext(String next, String confirm, int minLength) {
  if (next.length < minLength) return PasswordIssue.tooShort;
  if (confirm != next) return PasswordIssue.mismatch;
  return null;
}

/// Cambiar la contraseña con la sesión abierta. [minLength] viene de los parámetros del servidor
/// (`password_min_length`). El servidor vuelve a validar: esto solo evita viajes inútiles.
PasswordIssue? checkNewPassword({
  required String current,
  required String next,
  required String confirm,
  required int minLength,
}) {
  if (current.isEmpty || next.isEmpty || confirm.isEmpty) return PasswordIssue.empty;
  if (next == current) return PasswordIssue.sameAsCurrent;
  return _checkNext(next, confirm, minLength);
}

/// Recuperar la contraseña sin sesión, con el código que llegó al teléfono. El largo del código y
/// el mínimo de la contraseña los manda el servidor al pedir el código.
PasswordIssue? checkResetPassword({
  required String code,
  required String next,
  required String confirm,
  required int codeLength,
  required int minLength,
}) {
  if (code.isEmpty || next.isEmpty || confirm.isEmpty) return PasswordIssue.empty;
  if (code.length != codeLength) return PasswordIssue.badCode;
  return _checkNext(next, confirm, minLength);
}
