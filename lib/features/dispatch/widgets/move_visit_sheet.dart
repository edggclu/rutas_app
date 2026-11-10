import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/choice_group.dart';
import '../../../core/widgets/unsaved_guard.dart';
import '../../../domain/dispatch_rules.dart';
import '../../../domain/models/dispatch_models.dart';
import '../../../domain/session_errors.dart';
import '../../../providers/dispatch_providers.dart';
import 'day_choice.dart';

/// Hoja para mover una visita a otro día o a otro técnico. Devuelve un mensaje para mostrar si se
/// movió, o null si se canceló. [fromDate] y [from] son donde está hoy la visita.
Future<String?> showMoveVisitSheet(
  BuildContext context, {
  required DispatchVisit visit,
  required DateTime fromDate,
  required TechnicianRoute from,
  required List<({int id, String name})> technicians,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    enableDrag: false, // arrastrarla cierra sin preguntar; se cierra con Cancelar o tocando fuera
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _MoveVisitSheet(visit: visit, fromDate: fromDate, from: from, technicians: technicians),
  );
}

class _MoveVisitSheet extends ConsumerStatefulWidget {
  const _MoveVisitSheet({required this.visit, required this.fromDate, required this.from, required this.technicians});

  final DispatchVisit visit;
  final DateTime fromDate;
  final TechnicianRoute from;
  final List<({int id, String name})> technicians;

  @override
  ConsumerState<_MoveVisitSheet> createState() => _MoveVisitSheetState();
}

class _MoveVisitSheetState extends ConsumerState<_MoveVisitSheet> {
  late DateTime _date = dateOnly(widget.fromDate);
  late int _technicianId = widget.from.id;
  bool _busy = false;
  String? _error;

  DateTime get _today => dateOnly(DateTime.now());

  MoveIssue? get _issue => checkMove(
        visit: widget.visit,
        fromDate: widget.fromDate,
        fromTechnicianId: widget.from.id,
        toDate: _date,
        toTechnicianId: _technicianId,
        today: _today,
      );

  Future<void> _move() async {
    final navigator = Navigator.of(context); // se guardan antes del await
    final actions = ref.read(dispatchActionsProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await actions.moveVisit(
        visit: widget.visit,
        fromDate: widget.fromDate,
        fromTechnicianId: widget.from.id,
        toDate: _date,
        toTechnicianId: _technicianId,
      );
      navigator.pop(widget.visit.confirmedWithClient
          ? 'Visita movida. Administración avisará al cliente.'
          : 'Visita movida');
    } on ConflictException {
      navigator.pop('La visita ya empezó o cambió. Se actualizó la lista.');
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo mover. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final bottom = MediaQuery.of(context).padding.bottom;
    final changed = _issue != MoveIssue.nothingChanged;
    return UnsavedGuard(
      dirty: changed && !_busy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + keyboard + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mover visita', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${widget.visit.clientName} · ahora con ${widget.from.name}',
                  style: const TextStyle(color: AppColors.gris600)),
              if (widget.visit.confirmedWithClient)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.alertaSuave, borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    'Esta visita ya está confirmada con el cliente. Al moverla, administración recibe un aviso para avisarle.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),
              DayChoice(value: _date, today: _today, onChanged: (d) => setState(() => _date = d)),
              ChoiceGroup<int>(
                title: 'Técnico',
                options: [for (final t in widget.technicians) (t.id, t.name)],
                selected: _technicianId,
                onSelected: (id) => setState(() => _technicianId = id),
              ),
              if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.rojo)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _issue == null && !_busy ? _move : null,
                child: Text(_busy ? 'Moviendo…' : 'Mover visita'),
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
