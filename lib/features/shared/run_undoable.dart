import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/providers/actions_provider.dart';

import '../../application/visit_actions.dart';
import '../../core/widgets/undo_bar.dart';

/// Qué hacer con la pantalla después de guardar.
enum AfterSave { // las tres opciones que usan las pantallas
  stay, // se queda donde está
  pop, // cierra solo esta pantalla
  popToRoot, // vuelve hasta Mi día
}

/// Ejecuta una acción del técnico y se encarga de todo lo demás: cerrar la
/// pantalla, mostrar la barra de deshacer y avisar si algo falla.
/// Devuelve true si se guardó.
Future<bool> runUndoable( // un solo lugar para el esqueleto que antes se copiaba en cada pantalla
  BuildContext context, // dónde mostrar los avisos
  WidgetRef ref, { // para leer las acciones del técnico
  required Future<ActionReceipt> Function(VisitActions actions) action, // qué se ejecuta; recibe las acciones
  String? message, // texto de la barra cuando es fijo
  String Function()? messageBuilder, // texto de la barra cuando depende del resultado (se evalúa DESPUÉS de guardar)
  AfterSave after = AfterSave.stay, // qué hacer con la pantalla al guardar
  Future<void> Function()? beforeClose, // algo que mostrar antes de cerrar (por ejemplo, una ventana de aviso)
  VoidCallback? onError, // limpieza si falla (regresar el deslizable, desbloquear el botón)
  String errorMessage = 'No se pudo guardar. Intenta de nuevo.', // texto del aviso de error
}) async {
  assert(message != null || messageBuilder != null, 'Falta el texto de la barra'); // en desarrollo avisa si no se dio ninguno
  final messenger = ScaffoldMessenger.of(context); // se guarda antes del await (después ya puede no haber context)
  final navigator = Navigator.of(context); // se guarda antes del await
  final actions = ref.read(visitActionsProvider); // las acciones del técnico
  try { // si algo falla, se avisa
    final receipt = await action(actions); // ejecuta la acción y recibe el comprobante
    if (beforeClose != null) await beforeClose(); // si hay algo que mostrar antes de cerrar, lo muestra
    switch (after) { // qué hacer con la pantalla
      case AfterSave.stay: // se queda
        break; // no hace nada
      case AfterSave.pop: // cierra solo esta pantalla
        navigator.pop(); // vuelve a la anterior
      case AfterSave.popToRoot: // vuelve hasta Mi día
        navigator.popUntil((route) => route.isFirst); // cierra todo menos la primera pantalla
    }
    showUndoBar( // barra con cuenta regresiva
      messenger, // dónde mostrarla
      message: messageBuilder?.call() ?? message ?? '', // el texto (el dinámico gana si existe)
      seconds: receipt.graceSeconds, // duración (parámetro del servidor)
      onUndo: () => actions.undo(receipt), // si toca Deshacer, se borra de la cola
    );
    return true; // se guardó
  } catch (_) { // no se pudo guardar
    onError?.call(); // limpieza específica de la pantalla
    messenger.showSnackBar(SnackBar(content: Text(errorMessage))); // aviso de error
    return false; // no se guardó
  }
}