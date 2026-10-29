/// Lo que responde el servidor al pedir un código para recuperar la contraseña. Los números vienen
/// de sus parámetros, no del código de la app.
class PasswordResetInfo {
  const PasswordResetInfo({required this.codeLength, required this.minLength});

  final int codeLength; // cuántos dígitos tiene el código
  final int minLength; // largo mínimo de la contraseña nueva

  factory PasswordResetInfo.fromJson(Map<String, dynamic> j) => PasswordResetInfo(
        codeLength: (j['code_length'] as num).toInt(),
        minLength: (j['password_min_length'] as num).toInt(),
      );
}
