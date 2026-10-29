import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/map_launcher.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/toast.dart';
import '../../domain/models/models.dart';
import '../../domain/models/route_path.dart';
import '../../domain/rules/route_planner.dart';
import '../../providers/route_providers.dart';
import '../../providers/routing_providers.dart';
import '../my_day/open_visit.dart';
import 'widgets/route_map.dart';
import 'widgets/stop_panel.dart';

/// Mapa de ruta. El orden lo calcula la app (la visita más cercana, y de ahí la más cercana a esa);
/// el técnico puede quedarse con la sugerida o elegir con cuál empezar, y la ruta se rehace desde
/// esa. Las visitas cerradas ya no cuentan. Abajo, la parada que se está mirando.
class RouteMapScreen extends ConsumerStatefulWidget {
  const RouteMapScreen({super.key});

  @override
  ConsumerState<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends ConsumerState<RouteMapScreen> {
  int? _selectedId; // la parada que tocó en el mapa o en los números (null = la siguiente)

  void _startHere(Visit v) {
    ref.read(routeStartProvider.notifier).choose(v.id);
    setState(() => _selectedId = null);
    ScaffoldMessenger.of(context).toast('Ruta rehecha desde ${v.client.name}');
  }

  Future<void> _navigate(Visit v) async {
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    final ok = await openMap(lat: v.place.lat, lng: v.place.lng, label: v.client.name, address: v.place.address);
    if (!ok) messenger.toast('No se pudo abrir el mapa.');
  }

  void _detail(Visit v) => openVisit(context, v);

  /// "2 por hacer", "1 en curso" o las dos cosas.
  String _subtitle(RoutePlan plan) => [
        if (plan.ordered.isNotEmpty) '${plan.ordered.length} por hacer',
        if (plan.active.isNotEmpty) '${plan.active.length} en curso',
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(routePlanProvider);
    if (plan == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final path = ref.watch(routePathProvider(RouteStops(plan.stopPoints))).value; // por calles; null mientras llega
    final stop = plan.stops.where((v) => v.id == _selectedId).firstOrNull ?? plan.stops.firstOrNull; // la en curso también cuenta

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Mapa de ruta',
            subtitle: plan.stops.isEmpty ? 'No quedan visitas por hacer' : _subtitle(plan),
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: RouteMap(plan: plan, path: path, selectedId: stop?.id, onSelect: (id) => setState(() => _selectedId = id)),
          ),
          StopPanel(
            plan: plan,
            path: path,
            stop: stop,
            onSelect: (v) => setState(() => _selectedId = v.id),
            onNavigate: () => _navigate(stop!),
            onStartHere: () => _startHere(stop!),
            onDetail: () => _detail(stop!),
            onResetRoute: () => ref.read(routeStartProvider.notifier).clear(),
          ),
        ],
      ),
    );
  }
}
