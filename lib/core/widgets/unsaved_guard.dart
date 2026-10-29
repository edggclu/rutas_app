import 'package:flutter/material.dart';

/// Pregunta si se quiere salir sin guardar. Devuelve true si el usuario decide salir.
Future<bool> confirmDiscard(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Salir sin guardar?'),
      content: const Text('Si sales ahora, se pierde lo que cambiaste.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Seguir editando')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Salir sin guardar')),
      ],
    ),
  );
  return leave == true;
}

/// Envuelve una pantalla o una hoja con un formulario. Mientras [dirty] sea true, el botón atrás,
/// el gesto de volver y tocar fuera de una hoja piden confirmación antes de descartar lo escrito.
/// Las salidas del propio código (`Navigator.pop` al guardar) no pasan por aquí: para que la
/// flecha del encabezado también pregunte, debe llamar a `Navigator.maybePop`.
class UnsavedGuard extends StatelessWidget {
  const UnsavedGuard({super.key, required this.dirty, required this.child, this.onDiscard});

  final bool dirty;
  final Widget child;
  final Future<void> Function()? onDiscard; // limpieza si el usuario confirma salir (por ejemplo, borrar fotos)

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (!await confirmDiscard(context)) return;
        await onDiscard?.call();
        navigator.pop();
      },
      child: child,
    );
  }
}
