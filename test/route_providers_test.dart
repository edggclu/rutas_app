import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/events/event_types.dart';
import 'package:telyser_app/domain/models/app_settings.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/rules/visit_state.dart';
import 'package:telyser_app/providers/route_providers.dart';
import 'package:telyser_app/providers/settings_provider.dart';

Map<String, dynamic> _json(String path) => json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Un contenedor con la ruta de prueba, los parámetros de prueba y las acciones indicadas.
Future<ProviderContainer> _container([List<VisitEvent> events = const []]) async {
  final c = ProviderContainer(overrides: [
    myDayBaseProvider.overrideWith((ref) async => DayRoute.fromJson(_json('assets/mock/my_day.json'))),
    settingsProvider.overrideWith((ref) async => AppSettings.fromMap(_json('assets/mock/settings.json'))),
    visitEventsProvider.overrideWith((ref) => Stream.value(events)),
  ]);
  addTearDown(c.dispose);
  // Se escuchan para que Riverpod no los pause mientras se espera a que carguen.
  c.listen(myDayBaseProvider, (previous, next) {});
  c.listen(settingsProvider, (previous, next) {});
  c.listen(visitEventsProvider, (previous, next) {});
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return c;
}

List<int> _order(ProviderContainer c) => [for (final v in c.read(myDayProvider).value!.visits) v.id];

VisitEvent _ev(String type, int visitId, int minutes) =>
    VisitEvent(type: type, visitId: visitId, occurredAt: DateTime.utc(2026, 10, 6, 14, minutes));

void main() {
  test('el orden ya no viene del servidor: sale de la oficina con el vecino más cercano', () async {
    final c = await _container();
    expect(_order(c), [102, 101, 103]); // el servidor decía 101, 102, 103
    expect(c.read(routePlanProvider)!.suggestedFirstId, 102);
  });

  test('elegir otra primera visita rehace la ruta desde esa', () async {
    final c = await _container();
    c.read(routeStartProvider.notifier).choose(101);
    expect(_order(c), [101, 103, 102]);
    expect(c.read(routePlanProvider)!.isCustom, isTrue);
    c.read(routeStartProvider.notifier).clear(); // vuelve a la sugerida
    expect(_order(c), [102, 101, 103]);
  });

  test('una visita cerrada ya no cuenta: la ruta se rehace con las que faltan desde donde cerró', () async {
    final c = await _container([
      _ev(EventTypes.departureConfirmed, 102, 0),
      _ev(EventTypes.arrived, 102, 10),
      _ev(EventTypes.finished, 102, 40),
    ]);
    final plan = c.read(routePlanProvider)!;
    expect(plan.ordered.map((v) => v.id), [101, 103]); // sin la 102
    expect(_order(c), [101, 103, 102]); // la cerrada baja al final
  });

  test('la visita activa va primero y no se reordena', () async {
    final c = await _container([_ev(EventTypes.departureConfirmed, 103, 0)]);
    expect(_order(c).first, 103);
  });
}
