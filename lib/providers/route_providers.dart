import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/models/geo_point.dart';
import '../domain/models/models.dart';
import '../domain/models/media_item.dart';
import '../domain/rules/route_planner.dart';
import '../domain/rules/visit_state.dart';
import '../domain/rules/visit_summary.dart';
import 'infra_providers.dart';
import 'session_provider.dart';
import 'settings_provider.dart';

/// Ruta tal como la tiene el servidor. Con señal: descarga y guarda en el
/// teléfono. Sin señal: lee lo último guardado.
final myDayBaseProvider = FutureProvider<DayRoute>((ref) async { // se calcula una vez y se comparte
  ref.watch(sessionProvider); // si cambia la sesión, se vuelve a calcular
  final store = ref.watch(routeStoreProvider); // el almacén de la ruta
  final now = DateTime.now(); // la fecha de hoy
  try { // primero se intenta con el servidor
    final raw = await ref.watch(visitRepositoryProvider).fetchMyDay(now); // descarga el JSON
    await store.saveDay(raw); // lo guarda en el teléfono
    return DayRoute.fromJson(raw); // lo convierte en modelos
  } catch (_) { // sin señal o error
    final local = await store.loadDay(DateFormat('yyyy-MM-dd').format(now)); // lee lo guardado de hoy
    if (local != null) return local; // si lo hay, lo usa
    rethrow; // si no hay nada guardado, falla
  }
});

/// Acciones de la cola (incluidas las que siguen en gracia).
final visitEventsProvider = StreamProvider<List<VisitEvent>>((ref) { // se actualiza cada vez que cambia la cola
  return ref.watch(outboxRepositoryProvider).watchAll().map((rows) => [ // escucha la tabla de la cola
        for (final r in rows) // por cada fila
          VisitEvent( // la convierte en un evento de dominio
            type: r.type, // tipo
            visitId: r.visitId, // visita
            occurredAt: r.occurredAtUtc.toUtc(), // hora, normalizada a UTC (Drift la devuelve en local)
            payload: jsonDecode(r.payloadJson) as Map<String, dynamic>, // datos extra
          ),
      ]);
});

/// La ruta del servidor con el estado de cada visita calculado con la cola, todavía sin ordenar.
final appliedRouteProvider = Provider<AsyncValue<DayRoute>>((ref) {
  final base = ref.watch(myDayBaseProvider);
  final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[];
  return base.whenData((route) => applyEvents(route, events));
});

/// Con cuál visita eligió empezar el técnico (null = la que sugiere el algoritmo). Solo vive
/// mientras decide: al salir hacia esa visita, el estado ya queda guardado en la cola.
class RouteStartNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void choose(int visitId) => state = visitId;
  void clear() => state = null;
}

final routeStartProvider = NotifierProvider<RouteStartNotifier, int?>(RouteStartNotifier.new);

/// El orden de la ruta: vecino más cercano desde donde está el técnico, o desde la visita
/// que eligió. Las visitas cerradas no cuentan.
final routePlanProvider = Provider<RoutePlan?>((ref) {
  final route = ref.watch(appliedRouteProvider).value;
  if (route == null) return null;
  final settings = ref.watch(settingsProvider).value; // la oficina es de donde sale la primera ruta
  final lat = settings?.officeLat;
  final lng = settings?.officeLng;
  return planRoute(
    route.visits,
    office: lat == null || lng == null ? null : GeoPoint(lat, lng),
    firstId: ref.watch(routeStartProvider),
  );
});

/// Lo que ven las pantallas: la ruta con su estado y en el orden de [routePlanProvider].
final myDayProvider = Provider<AsyncValue<DayRoute>>((ref) {
  final plan = ref.watch(routePlanProvider);
  return ref.watch(appliedRouteProvider).whenData((route) => DayRoute(date: route.date, visits: plan?.all ?? route.visits));
});

/// Una visita por su id, siempre con el estado actual (servidor + cola).
final visitByIdProvider = Provider.family<Visit?, int>((ref, id) { // family = uno por cada id
  final route = ref.watch(myDayProvider).value; // la ruta ya calculada, si ya cargó
  if (route == null) return null; // todavía no carga
  for (final v in route.visits) { // recorre las visitas
    if (v.id == id) return v; // la encontró
  }
  return null; // ninguna coincide con ese id
});

/// Reloj que avisa cada segundo. SOLO sirve para redibujar la cuenta regresiva:
/// el tiempo real siempre se calcula desde la hora de llegada guardada.
final tickProvider = StreamProvider.autoDispose<DateTime>( // autoDispose: se apaga al salir de la pantalla
    (ref) => Stream.periodic( // crea un flujo que emite periódicamente
          const Duration(seconds: 1), // cada segundo
          (_) => DateTime.now().toUtc(), // emite la hora actual en UTC
        ));

/// Fotos y videos de una visita (se actualiza solo al tomar uno nuevo).
final mediaForVisitProvider = StreamProvider.autoDispose // autoDispose: se apaga al salir de la pantalla
    .family<List<MediaItem>, int>( // family: uno por cada id de visita (ahora de MediaItem)
        (ref, visitId) => // recibe el id de la visita
            ref.watch(mediaRepositoryProvider).watchForVisit(visitId)); // escucha los archivos de esa visita

/// Todo lo que se hizo en una visita (extras, solicitudes, cierre, notas), de la cola.
final visitSummaryProvider = Provider.family<VisitSummary, int>(
    (ref, visitId) => summarizeVisit(ref.watch(visitEventsProvider).value ?? const <VisitEvent>[], visitId));
