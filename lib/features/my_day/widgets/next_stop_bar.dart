import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/models.dart';
import '../../../providers/route_providers.dart';
import '../../departure/departure_screen.dart';
import '../../route/route_map_screen.dart';
import '../../shared/run_undoable.dart';

/// La barra de abajo de Mi día: a dónde sigue el técnico. Por la mañana abre la Salida con la lista
/// de material; entre una visita y otra sale directo a la siguiente. En los dos casos puede cambiar
/// con cuál empezar desde el mapa. No aparece si ya va en camino, está en un sitio o no faltan visitas.
class NextStopBar extends ConsumerWidget {
  const NextStopBar({super.key, required this.route});

  final DayRoute route;

  Future<void> _goNext(BuildContext context, WidgetRef ref, Visit next) async {
    final saved = await runUndoable(
      context,
      ref,
      action: (a) => a.departure.goTo(next),
      message: 'En camino a ${next.client.name}',
    );
    if (saved) ref.read(routeStartProvider.notifier).clear(); // la elección ya quedó guardada en la cola
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(routePlanProvider);
    if (plan == null || plan.ordered.isEmpty || plan.active.isNotEmpty) return const SizedBox.shrink();
    final next = plan.ordered.first;
    final morning = plan.done.isEmpty; // todavía no sale ninguna: es la Salida del día

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: morning ? 'Empiezas en ' : 'Sigue ',
                    style: const TextStyle(color: AppColors.gris600),
                    children: [TextSpan(text: next.client.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.gris900))],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RouteMapScreen())),
                child: const Text('Cambiar'),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: morning
                  ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DepartureScreen(route: route)))
                  : () => _goNext(context, ref, next),
              child: Text(morning ? 'Preparar Salida' : 'Ir a ${next.client.name}'),
            ),
          ),
        ],
      ),
    );
  }
}
