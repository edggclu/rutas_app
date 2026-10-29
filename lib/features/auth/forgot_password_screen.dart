import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/input_formatters.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/unsaved_guard.dart';
import '../../domain/models/password_reset.dart';
import '../../domain/password_rules.dart';
import '../../domain/session_errors.dart';
import '../../providers/actions_provider.dart';

/// Recuperar la contraseña sin ayuda de administración. Primero el usuario o teléfono: el servidor
/// manda un código al teléfono registrado. Después el código y la contraseña nueva. Al terminar,
/// regresa al login con el usuario ya escrito.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialLogin = ''});

  final String initialLogin; // lo que ya escribió en el login

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _login = TextEditingController(text: widget.initialLogin);
  final _code = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  PasswordResetInfo? _info; // null = todavía no pide el código (paso 1)
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _code.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _dirty => _info != null && (_code.text.isNotEmpty || _next.text.isNotEmpty || _confirm.text.isNotEmpty);

  /// Pide el código (paso 1) o lo vuelve a pedir (reenviar).
  Future<void> _requestCode({bool resend = false}) async {
    final messenger = ScaffoldMessenger.of(context); // se guardan antes del await
    final actions = ref.read(accountActionsProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await actions.requestReset(_login.text);
      if (!mounted) return;
      setState(() => _info = info);
      if (resend) messenger.toast('Te mandamos otro código');
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo pedir el código. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset(PasswordResetInfo info) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final actions = ref.read(accountActionsProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await actions.resetPassword(
        login: _login.text,
        code: _code.text,
        next: _next.text,
        confirm: _confirm.text,
        info: info,
      );
      navigator.pop(_login.text.trim()); // el login queda con el usuario escrito
      messenger.toast('Contraseña cambiada. Entra con la nueva.');
    } on InvalidResetCodeException {
      if (mounted) setState(() => _error = 'El código no es correcto o ya venció. Puedes pedir otro.');
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cambiar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  PasswordIssue? _issue(PasswordResetInfo info) => checkResetPassword(
        code: _code.text,
        next: _next.text,
        confirm: _confirm.text,
        codeLength: info.codeLength,
        minLength: info.minLength,
      );

  String? _hint(PasswordIssue? issue, PasswordResetInfo info) => switch (issue) {
        PasswordIssue.tooShort when _next.text.isNotEmpty => 'Usa al menos ${info.minLength} caracteres.',
        PasswordIssue.mismatch when _confirm.text.isNotEmpty => 'Las contraseñas nuevas no coinciden.',
        _ => null,
      };

  Widget _field(TextEditingController c, String label,
          {bool obscure = false, List<TextInputFormatter>? formatters, TextInputType? keyboard, String? helper}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          obscureText: obscure,
          enabled: !_busy,
          keyboardType: keyboard,
          inputFormatters: formatters,
          autocorrect: false,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(labelText: label, helperText: helper),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final info = _info;
    final bottom = MediaQuery.of(context).padding.bottom;
    final issue = info == null ? null : _issue(info);

    return UnsavedGuard(
      dirty: _dirty && !_busy,
      child: Scaffold(
        body: Column(
          children: [
            AppHeader(title: 'Recuperar contraseña', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (info == null) ...[
                    const Text(
                      'Escribe tu usuario o teléfono. Te mandamos un código al teléfono que tienes registrado.',
                      style: TextStyle(color: AppColors.gris600),
                    ),
                    const SizedBox(height: 16),
                    _field(_login, 'Usuario o teléfono', keyboard: TextInputType.emailAddress),
                  ] else ...[
                    Text(
                      'Te mandamos un código de ${info.codeLength} dígitos. Escríbelo con tu contraseña nueva.',
                      style: const TextStyle(color: AppColors.gris600),
                    ),
                    const SizedBox(height: 16),
                    _field(_code, 'Código', formatters: digitsInput(info.codeLength), keyboard: TextInputType.number),
                    _field(_next, 'Contraseña nueva', obscure: true, helper: 'Al menos ${info.minLength} caracteres'),
                    _field(_confirm, 'Repite la contraseña nueva', obscure: true),
                    if (_hint(issue, info) != null)
                      Text(_hint(issue, info)!, style: const TextStyle(color: AppColors.rojo)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy ? null : () => _requestCode(resend: true),
                        child: const Text('Reenviar código'),
                      ),
                    ),
                  ],
                  if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.rojo)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
              child: SizedBox(
                width: double.infinity,
                child: info == null
                    ? FilledButton(
                        onPressed: _login.text.trim().isEmpty || _busy ? null : _requestCode,
                        child: Text(_busy ? 'Enviando…' : 'Enviar código'),
                      )
                    : FilledButton(
                        onPressed: issue == null && !_busy ? () => _reset(info) : null,
                        child: Text(_busy ? 'Guardando…' : 'Cambiar contraseña'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
