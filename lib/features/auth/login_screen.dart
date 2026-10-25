import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/providers/session_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/session_errors.dart';

/// A1 · Login (tema oscuro navy).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  bool get _canSubmit => _user.text.trim().isNotEmpty && _pass.text.isNotEmpty; // sin usuario o contraseña no se envía

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).login(_user.text, _pass.text);
    } on WrongAccountException catch (e) { // la sesión expiró y entró otra persona
      if (mounted) setState(() => _error = 'Entra con la cuenta de ${e.expectedName}: tiene acciones sin enviar.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Usuario o contraseña incorrectos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // A2 · No hay recuperación automática de contraseña.
  void _forgotPassword() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recuperar contraseña',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'La app no recupera contraseñas por su cuenta. Contacta a '
              'Administración para que la restablezcan.',
              style: TextStyle(color: AppColors.gris600),
            ),
            const SizedBox(height: 20),
            // TODO: botón "Llamar a Administración" cuando se tenga el número
            // (vendrá de /api/settings).
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiredUser = ref.watch(expiredUserProvider); // no es null si la sesión expiró
    return Scaffold(
      backgroundColor: AppColors.navy900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.rojo,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Text(
                        'T',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'TELYSER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'App de campo',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gris400, fontSize: 14),
                  ),
                  if (expiredUser != null) ...[ // A3 · la sesión expiró: se avisa y se explica qué pasa con lo guardado
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.alertaSuave,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tu sesión expiró',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.alerta)),
                          const SizedBox(height: 4),
                          Text(
                            '${expiredUser.name}, vuelve a entrar para continuar. '
                            'Lo que guardaste sin enviar no se pierde.',
                            style: const TextStyle(color: AppColors.gris900, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const _FieldLabel('Usuario o teléfono'),
                  TextField(
                    controller: _user,
                    onChanged: (_) => setState(() {}), // revisa si ya se puede enviar
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('Contraseña'),
                  TextField(
                    controller: _pass,
                    onChanged: (_) => setState(() {}), // revisa si ya se puede enviar
                    obscureText: _obscure,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.gris400,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.rojoSuave),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _loading || !_canSubmit ? null : _submit,
                    style: FilledButton.styleFrom( // el estado desactivado debe verse sobre el fondo navy
                      disabledBackgroundColor: AppColors.rojo.withValues(alpha: 0.35),
                      disabledForegroundColor: Colors.white70,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: AppColors.gris200),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Versión 0.1.0 · Android',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gris400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.gris200,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
