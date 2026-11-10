import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/toast.dart';
import '../../domain/dispatch_rules.dart';
import '../../domain/models/dispatch_models.dart';
import '../../providers/dispatch_providers.dart';
import 'schedule_visit_screen.dart';
import 'widgets/decisions_section.dart';
import 'widgets/move_visit_sheet.dart';
import 'widgets/routes_section.dart';
import 'widgets/unassigned_section.dart';

enum _Section { decisions, today, unassigned, tomorrow }

/// Rutas (jefe de ruta): lo que requiere su decisión, las rutas de hoy, los trabajos por asignar
/// y las rutas de mañana. El jefe programa un trabajo, mete una urgencia en una ruta y mueve una visita
/// a otro día o a otro técnico. El orden de cada ruta lo decide el técnico, no el jefe.
class DispatchScreen extends ConsumerStatefulWidget {
  const DispatchScreen({super.key});

  @override
  ConsumerState<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends ConsumerState<DispatchScreen> {
  _Section _section = _Section.decisions;

  String _label(_Section s, DispatchBoard board) => switch (s) {
        _Section.decisions => 'Decisión (${board.decisions.length})',
        _Section.today => 'Hoy',
        _Section.unassigned => 'Por asignar (${board.unassigned.length})',
        _Section.tomorrow => 'Mañana',
      };

  void _schedule(DispatchBoard board, UnassignedJob job, {required bool urgent}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ScheduleVisitScreen(job: job, technicians: board.technicians, urgent: urgent),
      ));

  /// Abre la hoja para mover una visita. [date] es el día de la lista donde está.
  Future<void> _move(DispatchBoard board, DispatchVisit visit, TechnicianRoute from, DateTime date) async {
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    final message = await showMoveVisitSheet(context, visit: visit, fromDate: date, from: from, technicians: board.technicians);
    if (message != null) messenger.toast(message);
  }

  Widget _body(DispatchBoard board) {
    final today = dateOnly(DateTime.now());
    return switch (_section) {
      _Section.decisions => DecisionsSection(
          decisions: board.decisions,
          jobFor: (d) => board.unassigned.where((j) => j.id == d.jobId).firstOrNull,
          onScheduleUrgent: (job) => _schedule(board, job, urgent: true),
        ),
      _Section.today => RoutesSection(
          routes: board.today,
          showState: true,
          onMove: (v, from) => _move(board, v, from, today),
        ),
      _Section.unassigned => UnassignedSection(
          jobs: board.unassigned,
          onSchedule: (job, {required urgent}) => _schedule(board, job, urgent: urgent),
        ),
      _Section.tomorrow => RoutesSection(
          routes: board.tomorrow,
          showState: false,
          onMove: (v, from) => _move(board, v, from, today.add(const Duration(days: 1))),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(dispatchProvider);
    return Column(
      children: [
        const AppHeader(title: 'Rutas', subtitle: 'Todos los técnicos'),
        Expanded(
          child: board.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudo cargar. Revisa tu conexión.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
                    onPressed: () => ref.invalidate(dispatchProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            data: (data) => Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      for (final s in _Section.values) ...[
                        ChoiceChip(
                          label: Text(_label(s, data)),
                          selected: s == _section,
                          selectedColor: AppColors.navy900,
                          labelStyle: TextStyle(color: s == _section ? Colors.white : AppColors.gris900),
                          onSelected: (_) => setState(() => _section = s),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator( // jalar hacia abajo para actualizar
                    onRefresh: () async {
                      ref.invalidate(dispatchProvider);
                      await ref.read(dispatchProvider.future);
                    },
                    child: _body(data),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
