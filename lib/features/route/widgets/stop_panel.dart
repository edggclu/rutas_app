import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/time/time_utils.dart';
import '../../../domain/format.dart';
import '../../../domain/models/models.dart';
import '../../../domain/models/route_path.dart';
import '../../../domain/rules/route_planner.dart';
import 'route_map.dart';
import 'tier_chip.dart';

/// La tarjeta de abajo del mapa: la parada que se está mirando (por defecto, la siguiente) con su
/// dirección, la cita y los botones. En la siguiente parada el botón principal abre la navegación;
/// en otra, rehace la ruta empezando por ella.
class StopPanel extends StatelessWidget {
  const StopPanel({
    super.key,
    required this.plan,
    required this.path,
    required this.stop,
    required this.onSelect,
    required this.onNavigate,
    required this.onStartHere,
    required this.onDetail,
    required this.onResetRoute,
  });

  final RoutePlan plan;
  final RoutePath? path; // la ruta por calles, para los km
  final Visit? stop; // null cuando ya no quedan visitas
  final ValueChanged<Visit> onSelect;
  final VoidCallback onNavigate;
  final VoidCallback onStartHere;
  final VoidCallback onDetail;
  final VoidCallback onResetRoute;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final stop = this.stop;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: stop == null ? const _Done() : _Content(panel: this, stop: stop),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done();

  @override
  Widget build(BuildContext context) =>
      const Text('Ya cerraste todas tus visitas.', style: TextStyle(color: AppColors.gris600));
}

class _Content extends StatelessWidget {
  const _Content({required this.panel, required this.stop});

  final StopPanel panel;
  final Visit stop;

  @override
  Widget build(BuildContext context) {
    final plan = panel.plan;
    final index = plan.ordered.indexWhere((v) => v.id == stop.id);
    final isNext = index == 0;
    final km = index >= 0 ? plan.legKm(index, panel.path) : null; // por calles si ya se tiene
    final scheduled = stop.scheduledAt;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isNext ? (plan.isCustom ? 'SIGUIENTE PARADA · TU ELECCIÓN' : 'SIGUIENTE PARADA') : 'PARADA ${index + 1}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.gris600),
        ),
        if (plan.ordered.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: plan.ordered.length,
              separatorBuilder: (context, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => panel.onSelect(plan.ordered[i]),
                child: StopNumber(number: i + 1, next: i == 0, selected: plan.ordered[i].id == stop.id && i != 0),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text(stop.client.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            if (km != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.gris100, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${formatNumber(km, decimals: 1)} km',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gris900),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          stop.place.lat == null ? 'Sin ubicación en el mapa' : stop.place.address,
          style: const TextStyle(fontSize: 13, color: AppColors.gris600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TierChip(stop.client.tier),
            if (scheduled != null)
              Text(
                'Cita acordada: ${formatClock(scheduled)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.rojo),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: isNext ? panel.onNavigate : panel.onStartHere,
                child: Text(isNext ? 'Iniciar navegación' : 'Empezar por esta'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton(onPressed: panel.onDetail, child: const Text('Detalle de visita'))),
          ],
        ),
        if (plan.isCustom)
          Align(
            alignment: Alignment.center,
            child: TextButton(onPressed: panel.onResetRoute, child: const Text('Volver a la ruta sugerida')),
          ),
      ],
    );
  }
}
