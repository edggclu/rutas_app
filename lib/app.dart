import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/home_shell.dart';

class TelyserApp extends StatelessWidget {
  const TelyserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telyser',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

/// Sin sesión -> Login. Con sesión -> pestañas según rol y permisos.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return session == null ? const LoginScreen() : const HomeShell();
  }
}
