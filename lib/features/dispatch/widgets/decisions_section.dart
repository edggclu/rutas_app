import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/time/time_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/models/dispatch_models.dart';

/// Lo que requiere la decisión del jefe: urgencias arriba, y después detenidos, jornadas
/// propuestas, trabajos regresados, retrasos y llegadas fuera de orden.
class DecisionsSection extends StatelessWidget {
  const DecisionsSection({super.key, required this.decisions, required this.jobFor, required this.onScheduleUrgent});

  final List<Decision> decisions;
  final UnassignedJob? Function(Decision decision) jobFor; // el trabajo por asignar de esa urgencia, si lo hay
  final void Function(UnassignedJob job) onScheduleUrgent; // abre la pantalla para meterla en una ruta

  @override
  Widget build(BuildContext context) {
    if (decisions.isEmpty) {
      return const Center(child: Text('Nada requiere tu decisión.', style: TextStyle(color: AppColors.gris600)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: decisions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final d = decisions[i];
        final job = d.kind == DecisionKind.urgent ? jobFor(d) : null;
        return _DecisionCard(decision: d, onAct: job == null || !job.canSchedule ? null : () => onScheduleUrgent(job));
      },
    );
  }
}

/// El ícono y el color de cada tipo de decisión. La urgencia va en rojo.
({IconData icon, Color color, Color soft}) _style(DecisionKind k) => switch (k) {
      DecisionKind.urgent => (icon: Icons.priority_high, color: AppColors.rojoOscuro, soft: AppColors.rojoSuave),
      DecisionKind.blocked => (icon: Icons.pause_circle_outline, color: AppColors.alerta, soft: AppColors.alertaSuave),
      DecisionKind.continueProposed => (icon: Icons.event_repeat, color: AppColors.info, soft: AppColors.infoSuave),
      DecisionKind.returned => (icon: Icons.undo, color: AppColors.rojoOscuro, soft: AppColors.rojoSuave),
      DecisionKind.routeDelay => (icon: Icons.schedule, color: AppColors.alerta, soft: AppColors.alertaSuave),
      DecisionKind.outOfOrder => (icon: Icons.swap_vert, color: AppColors.info, soft: AppColors.infoSuave),
      DecisionKind.other => (icon: Icons.help_outline, color: AppColors.gris600, soft: AppColors.gris100),
    };

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.decision, required this.onAct});

  final Decision decision;
  final VoidCallback? onAct; // "Meter en una ruta" (solo en una urgencia que ya se puede programar)

  @override
  Widget build(BuildContext context) {
    final s = _style(decision.kind);
    final folio = decision.jobFolio;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: s.soft, borderRadius: BorderRadius.circular(10)),
            child: Icon(s.icon, color: s.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(decision.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(decision.detail, style: const TextStyle(fontSize: 13, color: AppColors.gris900)),
                const SizedBox(height: 4),
                Text(
                  [if (folio != null) folio, formatRelativeDay(decision.createdAt)].join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.gris600),
                ),
                if (onAct != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: onAct,
                    child: const Text('Meter en una ruta'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
