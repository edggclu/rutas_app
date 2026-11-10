import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/choice_group.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/unsaved_guard.dart';
import '../../domain/dispatch_rules.dart';
import '../../domain/models/dispatch_models.dart';
import '../../domain/session_errors.dart';
import '../../providers/dispatch_providers.dart';
import 'widgets/day_choice.dart';

/// Programar una visita de un trabajo por asignar: el día, el técnico responsable y, si hace falta,
/// acompañantes. Con [urgent] se mete en la ruta de hoy como urgencia y ese técnico recibe un aviso.
/// El orden dentro de la ruta no se decide aquí: lo elige el técnico.
class ScheduleVisitScreen extends ConsumerStatefulWidget {
  const ScheduleVisitScreen({super.key, required this.job, required this.technicians, this.urgent = false});

  final UnassignedJob job;
  final List<({int id, String name})> technicians;
  final bool urgent;

  @override
  ConsumerState<ScheduleVisitScreen> createState() => _ScheduleVisitScreenState();
}

class _ScheduleVisitScreenState extends ConsumerState<ScheduleVisitScreen> {
  late final DateTime _today = dateOnly(DateTime.now());
  late DateTime _date = _today;
  int? _technicianId;
  final Set<int> _companions = {};
  bool _busy = false;

  bool get _dirty => _technicianId != null || _companions.isNotEmpty || _date != _today;

  ScheduleIssue? get _issue => checkSchedule(
        job: widget.job,
        technicianId: _technicianId,
        date: _date,
        today: _today,
        companionIds: _companions,
      );

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context); // se guardan antes del await
    final navigator = Navigator.of(context);
    final actions = ref.read(dispatchActionsProvider);
    setState(() => _busy = true);
    try {
      await actions.scheduleVisit(
        job: widget.job,
        date: _date,
        technicianId: _technicianId!,
        companionIds: _companions,
        urgent: widget.urgent,
      );
      navigator.pop();
      messenger.toast(widget.urgent ? 'Urgencia en la ruta. Se avisa al técnico.' : 'Visita programada');
    } on ConflictException {
      navigator.pop(); // el tablero ya se volvió a pedir
      messenger.toast('Otra persona ya programó este trabajo.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.toast('No se pudo programar. Revisa tu conexión.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final bottom = MediaQuery.of(context).padding.bottom;
    final others = [for (final t in widget.technicians) if (t.id != _technicianId) t];
    return UnsavedGuard(
      dirty: _dirty && !_busy,
      child: Scaffold(
        body: Column(
          children: [
            AppHeader(
              subtitle: job.folio,
              title: widget.urgent ? 'Meter en una ruta' : 'Programar visita',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(job.placeName, style: const TextStyle(fontSize: 13, color: AppColors.gris600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.urgent)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Va en la ruta de hoy. El técnico que elijas recibe un aviso.',
                          style: TextStyle(color: AppColors.gris600)),
                    )
                  else
                    DayChoice(value: _date, today: _today, onChanged: (d) => setState(() => _date = d)),
                  ChoiceGroup<int>(
                    title: 'Técnico responsable',
                    options: [for (final t in widget.technicians) (t.id, t.name)],
                    selected: _technicianId,
                    onSelected: (id) => setState(() {
                      _technicianId = id;
                      _companions.remove(id); // el responsable no puede ser su propio acompañante
                    }),
                  ),
                  if (_technicianId != null && others.isNotEmpty) ...[
                    const Text('Acompañantes (opcional)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gris600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in others)
                          FilterChip(
                            label: Text(t.name),
                            selected: _companions.contains(t.id),
                            onSelected: (on) => setState(() => on ? _companions.add(t.id) : _companions.remove(t.id)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _issue == null && !_busy ? _save : null,
                  child: Text(_busy ? 'Guardando…' : (widget.urgent ? 'Meter en la ruta' : 'Programar visita')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
