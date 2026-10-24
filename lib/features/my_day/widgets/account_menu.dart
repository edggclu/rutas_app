import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget
import 'package:telyser_app/providers/actions_provider.dart';
import 'package:telyser_app/providers/session_provider.dart';

import '../../../core/theme/app_colors.dart'; // colores

enum _MenuAction { logout, resetDemo } // las dos opciones del menú

/// Menú de tres puntos del encabezado de Mi día: cerrar sesión y reiniciar la demo.
class AccountMenu extends ConsumerWidget { // widget que puede leer providers
  const AccountMenu({super.key}); // sin datos

  /// Pide confirmación y borra lo guardado en el teléfono.
  Future<void> _resetDemo(BuildContext context, WidgetRef ref) async { // se ejecuta al elegir "Reiniciar"
    final ok = await showDialog<bool>( // ventana de confirmación (evita borrar sin querer en plena presentación)
      context: context, // sobre esta pantalla
      builder: (ctx) => AlertDialog( // la ventana
        title: const Text('Reiniciar datos de demo'), // título
        content: const Text( // explicación
          'Se borran las acciones y fotos guardadas en este teléfono. Las visitas vuelven a su estado inicial.',
        ),
        actions: [ // botones
          TextButton( // cancelar
            onPressed: () => Navigator.of(ctx).pop(false), // cierra devolviendo false
            child: const Text('Cancelar'), // texto
          ),
          FilledButton( // confirmar
            onPressed: () => Navigator.of(ctx).pop(true), // cierra devolviendo true
            child: const Text('Reiniciar'), // texto
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return; // si canceló, o la pantalla ya no existe, no hace nada
    await ref.read(demoResetProvider)(); // borra la cola y las fotos
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { // dibuja el menú
    return PopupMenuButton<_MenuAction>( // botón que abre un menú
      icon: const Icon(Icons.more_vert, color: AppColors.gris200), // tres puntos
      onSelected: (action) { // al elegir una opción
        switch (action) { // según cuál
          case _MenuAction.logout: // cerrar sesión
            ref.read(sessionProvider.notifier).logout(); // borra la sesión: la app vuelve al login
          case _MenuAction.resetDemo: // reiniciar la demo
            _resetDemo(context, ref); // confirma y borra
        }
      },
      itemBuilder: (_) => const [ // las opciones
        PopupMenuItem(value: _MenuAction.logout, child: Text('Cerrar sesión')), // opción 1
        PopupMenuItem(value: _MenuAction.resetDemo, child: Text('Reiniciar datos de demo')), // opción 2
      ],
    );
  }
}