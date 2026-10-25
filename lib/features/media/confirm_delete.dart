import 'package:flutter/material.dart';

import '../../domain/models/media_item.dart';

/// Pregunta antes de borrar una foto o video, porque no se puede deshacer.
/// Devuelve true si el técnico confirma.
Future<bool> confirmDeleteMedia(BuildContext context, MediaItem item) async {
  final noun = item.kind.isVideo ? 'este video' : 'esta foto';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('¿Borrar $noun?'),
      content: const Text('Se quita de la visita y no se podrá recuperar.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Borrar')),
      ],
    ),
  );
  return ok == true;
}
