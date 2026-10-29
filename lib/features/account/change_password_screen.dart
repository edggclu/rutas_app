import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/unsaved_guard.dart';
import '../../domain/password_rules.dart';
import '../../domain/session_errors.dart';
import '../../providers/actions_provider.dart';
import '../../providers/settings_provider.dart';

/// Cambiar la contraseña, sin pasar por administración. Pide la actual y la nueva dos veces.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error; // lo que respondió el servidor (contraseña actual incorrecta o sin conexión)

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _dirty => _current.text.isNotEmpty || _next.text.isNotEmpty || _confirm.text.isNotEmpty;

  PasswordIssue? _issue(int minLength) => checkNewPassword(
        current: _current.text,
        next: _next.text,
        confirm: _confirm.text,
        minLength: minLength,
      );

  /// El aviso de lo que falta, solo cuando ya se escribió algo en el campo que lo causa.
  String? _hint(PasswordIssue? issue, int minLength) => switch (issue) {
        PasswordIssue.tooShort when _next.text.isNotEmpty => 'Usa al menos $minLength caracteres.',
        PasswordIssue.sameAsCurrent => 'La nueva no puede ser igual a la actual.',
        PasswordIssue.mismatch when _confirm.text.isNotEmpty => 'Las contraseñas nuevas no coinciden.',
        _ => null,
      };

  Future<void> _save(int minLength) async {
    final messenger = ScaffoldMessenger.of(context); // se guardan antes del await
    final navigator = Navigator.of(context);
    final actions = ref.read(accountActionsProvider);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await actions.changePassword(
        current: _current.text,
        next: _next.text,
        confirm: _confirm.text,
        minLength: minLength,
      );
      navigator.pop();
      messenger.toast('Contraseña cambiada');
    } on WrongPasswordException {
      if (mounted) setState(() => _error = 'La contraseña actual no es correcta.');
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cambiar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController c, String label, {String? helper}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          obscureText: true,
          enabled: !_saving,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(labelText: label, helperText: helper),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final minLength = ref.watch(settingsProvider).value?.passwordMinLength; // viene del servidor
    final issue = minLength == null ? PasswordIssue.empty : _issue(minLength);
    final bottom = MediaQuery.of(context).padding.bottom;
    return UnsavedGuard(
      dirty: _dirty && !_saving,
      child: Scaffold(
        body: Column(
          children: [
            AppHeader(
              title: 'Cambiar contraseña',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _field(_current, 'Contraseña actual'),
                  _field(_next, 'Contraseña nueva',
                      helper: minLength == null ? null : 'Al menos $minLength caracteres'),
                  _field(_confirm, 'Repite la contraseña nueva'),
                  if (minLength != null && _hint(issue, minLength) != null)
                    Text(_hint(issue, minLength)!, style: const TextStyle(color: AppColors.rojo)),
                  if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.rojo)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: issue == null && !_saving ? () => _save(minLength!) : null,
                  child: Text(_saving ? 'Guardando…' : 'Cambiar contraseña'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
