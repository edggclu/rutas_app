import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../domain/models/dispatch_models.dart';
import '../../../domain/models/enums.dart';
import '../../my_day/visit_tags.dart';

/// Los trabajos aprobados que todavía no tienen visita, con el semáforo de lo que falta. Un
/// trabajo en rojo todavía no se puede programar.
class UnassignedSection extends StatelessWidget {
  const UnassignedSection({super.key, required this.jobs});

  final List<UnassignedJob> jobs;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const Center(child: Text('No hay trabajos por asignar.', style: TextStyle(color: AppColors.gris600)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _JobCard(job: jobs[i]),
    );
  }
}

Color _lightColor(LightState s) => switch (s) {
      LightState.ok => AppColors.ok,
      LightState.warning => AppColors.alerta,
      LightState.blocked => AppColors.rojo,
    };

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final UnassignedJob job;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(job.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              Text(job.folio, style: const TextStyle(fontSize: 12, color: AppColors.gris600)),
            ],
          ),
          Text(job.placeName, style: const TextStyle(fontSize: 13, color: AppColors.gris600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              jobTypeChip(job.type),
              if (job.priority == Priority.urgent)
                const TagChip(label: 'URGENTE', background: AppColors.rojo, foreground: Colors.white),
              if (job.canSchedule)
                const TagChip(label: 'Se puede programar', background: AppColors.okSuave, foreground: AppColors.ok)
              else
                const TagChip(label: 'Aún no se puede programar', background: AppColors.rojoSuave, foreground: AppColors.rojoOscuro),
            ],
          ),
          const SizedBox(height: 10),
          for (final l in Light.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: _lightColor(job.lights[l]!), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(l.label, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
