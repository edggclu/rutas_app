import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/models/models.dart';
import '../domain/models/media_item.dart';
import '../domain/rules/visit_state.dart';
import 'infra_providers.dart';
import 'session_provider.dart';

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

/// Lo que ven las pantallas: ruta del servidor + acciones de la cola.
final myDayProvider = Provider<AsyncValue<DayRoute>>((ref) { // combina dos fuentes
  final base = ref.watch(myDayBaseProvider); // la ruta del servidor
  final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[]; // la cola
  return base.whenData((route) => applyEvents(route, events)); // la ruta con el estado calculado
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