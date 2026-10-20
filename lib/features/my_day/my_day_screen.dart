import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/features/site/site_screen.dart';
import 'package:telyser_app/providers/route_providers.dart';
import 'package:telyser_app/providers/session_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/time_utils.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/tag_chip.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../../domain/rules/technician_state.dart';
import 'visit_card.dart';
import '../departure/departure_screen.dart';
import 'visit_detail_loader.dart';

/// C1 · Mi día: la ruta del día en orden y el estado del técnico.
class MyDayScreen extends ConsumerWidget {
  const MyDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)!.user;
    final day = ref.watch(myDayProvider);

    return day.when(
      loading: () => Column(
        children: [
          AppHeader(title: 'Hola, ${user.name}'),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
      error: (e, _) => Column(
        children: [
          AppHeader(title: 'Hola, ${user.name}'),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudo cargar tu ruta.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
                    onPressed: () => ref.invalidate(myDayBaseProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      data: (route) => _Content(user: user, route: route),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.user, required this.route});

  final AppUser user;
  final DayRoute route;

  @override
  Widget build(BuildContext context) {
    final state = computeTechnicianState(route.visits);

    // Las visitas Hechas se atenúan y bajan al final.
    final visits = [
      ...route.visits.where((v) => v.status != VisitStatus.done),
      ...route.visits.where((v) => v.status == VisitStatus.done),
    ];
    final canPrepareDeparture = route.visits.isNotEmpty &&
        route.visits.every((v) =>
            v.status == VisitStatus.pending);

    return Column(
      children: [
        AppHeader(
          subtitle: formatLongDate(route.date),
          title: 'Hola, ${user.name}',
          trailing: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mis trabajos llega con el paso 5.')),
            ),
            child: const Text(
              'Mis trabajos ›',
              style: TextStyle(
                color: AppColors.rojoSuave,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          bottom: Align(
            alignment: Alignment.centerLeft,
            child: _StateChip(state),
          ),
        ),
        Expanded(
          child: visits.isEmpty
              ? const _EmptyDay()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tu ruta de hoy',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${visits.length} ${visits.length == 1 ? 'visita' : 'visitas'}',
                          style: const TextStyle(
                              color: AppColors.gris600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final v in visits) ...[
                      VisitCard(
                        visit: v,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => v.status == VisitStatus.onSite // si la visita ya está En sitio
                              ? SiteScreen(visitId: v.id) // abre la pantalla de trabajo
                              : VisitDetailLoader(visitId: v.id), // si no, abre la tarjeta de visita
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
        if (canPrepareDeparture)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: FilledButton(
              child: Text('Preparar Salida'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DepartureScreen(route: route),
                )
              ),
            ),
          ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip(this.state);
  final TechnicianState state;

  @override
  Widget build(BuildContext context) {
    switch (state.kind) {
      case TechStateKind.enRoute:
        return TagChip(
            label: state.label,
            background: AppColors.infoSuave,
            foreground: AppColors.info);
      case TechStateKind.onSite:
        return TagChip(
            label: state.label,
            background: AppColors.okSuave,
            foreground: AppColors.ok);
      case TechStateKind.free:
        return TagChip(
            label: state.label,
            background: AppColors.gris200,
            foreground: AppColors.gris900);
    }
  }
}

/// V1 · Estado vacío.
class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.gris100,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Text(
                '0',
                style: TextStyle(
                    fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.gris400),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hoy no tienes visitas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Si te asignan una urgencia, te llegará un aviso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gris600),
            ),
          ],
        ),
      ),
    );
  }
}
