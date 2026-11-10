import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/time/time_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../domain/dispatch_rules.dart';
import '../../../domain/models/dispatch_models.dart';
import '../../../domain/rules/technician_state.dart';
import '../../my_day/visit_tags.dart';

/// Las rutas de todos los técnicos en un día (hoy o mañana): su estado y sus visitas. Una visita que
/// todavía no empieza se puede mover a otro día o a otro técnico tocándola.
class RoutesSection extends StatelessWidget {
  const RoutesSection({super.key, required this.routes, required this.showState, required this.onMove});

  final List<TechnicianRoute> routes;
  final bool showState; // el estado "En sitio en…" solo tiene sentido hoy
  final void Function(DispatchVisit visit, TechnicianRoute from) onMove; // abre la hoja para mover

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const Center(child: Text('No hay rutas.', style: TextStyle(color: AppColors.gris600)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _TechnicianCard(route: routes[i], showState: showState, onMove: onMove),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({required this.route, required this.showState, required this.onMove});

  final TechnicianRoute route;
  final bool showState;
  final void Function(DispatchVisit visit, TechnicianRoute from) onMove;

  @override
  Widget build(BuildContext context) {
    final state = technicianStateOf([for (final v in route.visits) (status: v.status, client: v.clientName)]);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(route.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              if (showState) _StateChip(state),
            ],
          ),
          const SizedBox(height: 8),
          if (route.visits.isEmpty)
            const Text('Sin visitas.', style: TextStyle(color: AppColors.gris600))
          else
            for (final (i, v) in route.visits.indexed)
              InkWell(
                onTap: canMoveVisit(v) ? () => onMove(v, route) : null, // solo si todavía no empieza
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 22, child: Text('${i + 1}', style: const TextStyle(color: AppColors.gris600))),
                      Expanded(
                        child: Text(
                          [v.clientName, if (v.scheduledAt != null) formatClock(v.scheduledAt!)].join(' · '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      statusTag(v.status, v.result, v.dayNumber),
                      if (canMoveVisit(v)) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.swap_horiz, size: 18, color: AppColors.gris600), // se puede mover
                      ],
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip(this.state);

  final TechnicianState state;

  @override
  Widget build(BuildContext context) => switch (state.kind) {
        TechStateKind.enRoute => TagChip(label: state.label, background: AppColors.infoSuave, foreground: AppColors.info),
        TechStateKind.onSite => TagChip(label: state.label, background: AppColors.okSuave, foreground: AppColors.ok),
        TechStateKind.free => TagChip(label: state.label, background: AppColors.gris200, foreground: AppColors.gris900),
      };
}
