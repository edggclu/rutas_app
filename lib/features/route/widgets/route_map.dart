import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/geo_point.dart';
import '../../../domain/models/route_path.dart';
import '../../../domain/rules/route_planner.dart';

LatLng _ll(GeoPoint p) => LatLng(p.lat, p.lng);

/// El mapa de la ruta. Las visitas que faltan van numeradas en el orden de la ruta: la siguiente
/// parada, rellena en rojo, y las demás en blanco con borde rojo. La visita en curso va en verde y
/// las cerradas en gris. Se pueden tocar la visita en curso y las que faltan. Los mosaicos necesitan
/// internet: sin señal el mapa queda en blanco, pero los puntos siguen ahí.
class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.plan, required this.path, required this.selectedId, required this.onSelect});

  final RoutePlan plan;
  final RoutePath? path; // la ruta por calles; null = todavía no llega o no hay servicio
  final int? selectedId; // la parada que se está mirando
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final start = plan.start;
    final line = <LatLng>[
      if (start != null) _ll(start),
      for (final v in plan.ordered)
        if (pointOf(v) != null) _ll(pointOf(v)!),
    ];
    final all = <LatLng>[
      ...line,
      for (final v in [...plan.active, ...plan.done])
        if (pointOf(v) != null) _ll(pointOf(v)!),
    ];

    return FlutterMap(
      options: MapOptions(
        initialCenter: all.isEmpty ? const LatLng(20.65, -105.22) : all.first,
        initialZoom: 11,
        initialCameraFit: all.length >= 2
            ? CameraFit.coordinates(coordinates: all, padding: const EdgeInsets.all(56), maxZoom: 15)
            : null,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.telyser_app',
        ),
        PolylineLayer(
          polylines: [
            Polyline( // por calles si ya llegó; si no, la línea recta, punteada para que se note que es aproximada
              points: path != null ? [for (final p in path!.points) _ll(p)] : line,
              strokeWidth: 4,
              color: AppColors.rojo.withValues(alpha: 0.65),
              pattern: path != null ? const StrokePattern.solid() : StrokePattern.dashed(segments: const [10, 8]),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (start != null)
              Marker(
                point: _ll(start),
                width: 28,
                height: 28,
                child: const _Dot(fill: AppColors.navy900, ring: Colors.white, child: Icon(Icons.flag, size: 14, color: Colors.white)),
              ),
            for (final v in plan.done) // las cerradas: grises, solo para ubicarse
              if (pointOf(v) != null)
                Marker(
                  point: _ll(pointOf(v)!),
                  width: 28,
                  height: 28,
                  child: const _Dot(fill: AppColors.gris400, ring: Colors.white, child: Icon(Icons.check, size: 14, color: Colors.white)),
                ),
            for (final v in plan.active) // la que va En camino o En sitio
              if (pointOf(v) != null)
                Marker(
                  point: _ll(pointOf(v)!),
                  width: 38,
                  height: 38,
                  child: GestureDetector(onTap: () => onSelect(v.id), child: ActiveStop(selected: v.id == selectedId)),
                ),
            for (var i = 0; i < plan.ordered.length; i++)
              if (pointOf(plan.ordered[i]) != null)
                Marker(
                  point: _ll(pointOf(plan.ordered[i])!),
                  width: 38,
                  height: 38,
                  child: GestureDetector(
                    onTap: () => onSelect(plan.ordered[i].id),
                    child: StopNumber(
                      number: i + 1,
                      next: i == 0,
                      selected: plan.ordered[i].id == selectedId && i != 0,
                    ),
                  ),
                ),
          ],
        ),
        const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap')]),
      ],
    );
  }
}

/// El número de una parada. La siguiente va rellena en rojo; las demás, en blanco con borde rojo.
/// La que se está mirando lleva un anillo oscuro.
class StopNumber extends StatelessWidget {
  const StopNumber({super.key, required this.number, required this.next, this.selected = false, this.size = 34});

  final int number;
  final bool next;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _Dot(
      size: size,
      fill: next ? AppColors.rojo : Colors.white,
      ring: selected ? AppColors.navy900 : AppColors.rojo,
      ringWidth: selected ? 3 : 2,
      child: Text(
        '$number',
        style: TextStyle(color: next ? Colors.white : AppColors.rojo, fontWeight: FontWeight.w700, fontSize: size * 0.42),
      ),
    );
  }
}

/// La visita en curso (En camino o En sitio): un círculo verde con el símbolo de ubicación.
class ActiveStop extends StatelessWidget {
  const ActiveStop({super.key, this.selected = false, this.size = 34});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => _Dot(
        size: size,
        fill: AppColors.ok,
        ring: selected ? AppColors.navy900 : Colors.white,
        ringWidth: selected ? 3 : 2,
        child: Icon(Icons.my_location, size: size * 0.5, color: Colors.white),
      );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.fill, required this.ring, required this.child, this.size, this.ringWidth = 2});

  final Color fill;
  final Color ring;
  final Widget child;
  final double? size;
  final double ringWidth;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: ringWidth),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: child,
      );
}
