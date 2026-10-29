import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/time/time_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/unsaved_guard.dart';
import '../../../domain/rules/visit_summary.dart';
import '../../shared/run_undoable.dart';

/// Las notas que el técnico agregó a una visita ya cerrada, y el botón para agregar otra.
/// Lo ya guardado no se edita: la nota solo suma.
class NotesSection extends ConsumerWidget {
  const NotesSection({super.key, required this.visitId, required this.notes});

  final int visitId;
  final List<VisitNote> notes;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      enableDrag: false, // arrastrarla cierra sin preguntar; se cierra con Cancelar o tocando fuera
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _NoteSheet(),
    );
    if (text == null || !context.mounted) return; // canceló
    await runUndoable(
      context,
      ref,
      action: (a) => a.closing.addNote(visitId: visitId, text: text),
      message: 'Nota agregada',
      after: AfterSave.stay,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final n in notes) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.text),
                const SizedBox(height: 4),
                Text(formatRelativeDay(n.at), style: const TextStyle(fontSize: 12, color: AppColors.gris600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: () => _add(context, ref),
          icon: const Icon(Icons.note_add_outlined),
          label: const Text('Agregar nota'),
        ),
      ],
    );
  }
}

/// La hoja donde se escribe la nota. Devuelve el texto, o null si se cancela.
class _NoteSheet extends StatefulWidget {
  const _NoteSheet();

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final bottom = MediaQuery.of(context).padding.bottom;
    return UnsavedGuard(
      dirty: _ctrl.text.trim().isNotEmpty,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + keyboard + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Agregar nota', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Lo que ya guardaste no cambia. La nota se suma a la visita.',
                style: TextStyle(color: AppColors.gris600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: 4,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Nota', helperText: 'Ej. "Olvidé anotar el cable sobrante"'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _ctrl.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_ctrl.text.trim()),
                child: const Text('Guardar nota'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Cancelar')),
            ],
          ),
        ),
      ),
    );
  }
}
