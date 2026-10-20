import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/providers/session_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../my_day/my_day_screen.dart';
import 'app_tab_bar.dart';

/// Una sola app: las pestañas dependen del rol y los permisos.
///  - Técnico: Mi día · Avisos
///  - + Ingeniero: agrega Por validar
///  - + Coordina rutas (jefe de ruta): agrega Rutas
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider)!.user;

    final tabs = <({AppTabItem item, Widget page})>[
      (item: const AppTabItem('Mi día'), page: const MyDayScreen()),
      if (user.isDispatcher)
        (
          item: const AppTabItem('Rutas'),
          page: const _ComingSoon('Rutas', 'Paso 6 del orden de construcción.'),
        ),
      if (user.isEngineer)
        (
          item: const AppTabItem('Por validar'),
          page: const _ComingSoon('Por validar', 'Paso 5 del orden de construcción.'),
        ),
      (
        item: const AppTabItem('Avisos'),
        page: const _ComingSoon('Avisos', 'Llega con las notificaciones (paso 7).'),
      ),
    ];

    if (_index >= tabs.length) _index = 0;

    return Scaffold(
      body: IndexedStack(index: _index, children: [for (final t in tabs) t.page]),
      bottomNavigationBar: AppTabBar(
        items: [for (final t in tabs) t.item],
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon(this.title, this.note);
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(title: title),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                note,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gris600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
