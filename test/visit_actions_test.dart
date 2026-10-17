import 'dart:convert'; // jsonDecode para leer el payload guardado
import 'dart:io'; // File para leer el JSON de prueba

import 'package:drift/native.dart'; // base de datos en memoria para tests
import 'package:flutter_test/flutter_test.dart'; // herramientas de prueba
import 'package:telyser_app/data/local/app_database.dart'; // la base local
import 'package:telyser_app/data/local/outbox_repository.dart'; // la cola
import 'package:telyser_app/data/location_service.dart'; // GeoPoint y LocationService
import 'package:telyser_app/data/visit_actions.dart'; // las acciones que se prueban
import 'package:telyser_app/domain/event_types.dart'; // nombres de eventos
import 'package:telyser_app/domain/models.dart'; // DayRoute y Visit

/// Ubicación falsa: devuelve siempre el punto que se le indique (o null).
class _FakeLocation implements LocationService { // cumple el mismo contrato que la real
  _FakeLocation(this.point); // recibe el punto a devolver
  final GeoPoint? point; // el punto falso (null = "no hay ubicación")
  @override
  Future<GeoPoint?> currentPosition() async => point; // devuelve el punto sin tocar el GPS
}

void main() {
  late AppDatabase db; // base en memoria
  late OutboxRepository outbox; // la cola
  late List<Visit> visits; // las visitas del JSON de prueba

  setUp(() { // se ejecuta antes de cada prueba
    db = AppDatabase.forTesting(NativeDatabase.memory()); // base nueva y vacía
    outbox = OutboxRepository(db, now: () => DateTime.utc(2026, 10, 6, 12)); // cola con reloj fijo
    final raw = File('assets/mock/my_day.json').readAsStringSync(); // lee el JSON de prueba
    visits = DayRoute.fromJson(json.decode(raw) as Map<String, dynamic>).visits; // lo convierte en visitas
  });

  tearDown(() => db.close()); // cierra la base al terminar cada prueba

  VisitActions build(GeoPoint? point) => // arma las acciones con la ubicación que se indique
      VisitActions(outbox, () async => 10, _FakeLocation(point)); // 10 = segundos para deshacer

  test('salida sin faltantes: solo encola la salida, en gracia', () async {
    final receipt = await build(null).confirmDeparture(visits: visits, missing: {}); // confirma la salida sin faltantes
    final rows = await db.select(db.outboxEvents).get(); // lee la cola completa

    expect(rows.map((e) => e.type), [EventTypes.departureConfirmed]); // solo hay un evento: la salida
    expect(rows.single.visitId, 101); // de la primera visita
    expect(rows.single.state, 'grace'); // en tiempo de gracia
    expect(receipt.graceSeconds, 10); // el comprobante trae los 10 segundos
    expect(await outbox.nextBatch(), isEmpty); // aún no es enviable
  });

  test('con faltantes: el aviso va ANTES que la salida', () async {
    final tools = visits.first.checklist.tools; // las herramientas de la visita 101
    await build(null).confirmDeparture(visits: visits, missing: {101: tools}); // confirma con la escalera faltante
    final rows = await db.select(db.outboxEvents).get(); // lee la cola

    expect(rows.map((e) => e.type), // el orden de los eventos
        [EventTypes.missingItems, EventTypes.departureConfirmed]); // primero faltantes, luego salida
    final items = (jsonDecode(rows.first.payloadJson)['items']) as List; // los renglones del primer evento
    expect(items.single['text'], 'Escalera de 6 m'); // el texto del renglón
    expect(items.single['kind'], 'tool'); // es herramienta
  });

  test('deshacer borra todo lo que se encoló', () async {
    final actions = build(null); // las acciones
    final tools = visits.first.checklist.tools; // herramientas de la visita 101
    final receipt = await actions.confirmDeparture(visits: visits, missing: {101: tools}); // encola dos eventos
    await actions.undo(receipt); // deshace
    expect(await db.select(db.outboxEvents).get(), isEmpty); // la cola queda vacía
  });

  test('Llegué guarda el modo manual y las coordenadas', () async {
    final receipt = await build(const GeoPoint(20.7002, -105.2943)).arrive(visitId: 101); // llega con ubicación
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila de la cola
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>; // los datos guardados

    expect(row.type, EventTypes.arrived); // el tipo es "llegué"
    expect(row.visitId, 101); // de la visita 101
    expect(row.state, 'grace'); // en tiempo de gracia
    expect(payload['mode'], 'manual'); // se marcó a mano
    expect(payload['lat'], 20.7002); // latitud guardada
    expect(payload['lng'], -105.2943); // longitud guardada
    expect(receipt.uuids, [row.uuid]); // el comprobante apunta a esa fila
  });

  test('Llegué funciona aunque no haya ubicación', () async {
    await build(null).arrive(visitId: 101); // llega sin GPS
    final row = (await db.select(db.outboxEvents).get()).single; // la fila guardada
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>; // sus datos

    expect(row.type, EventTypes.arrived); // se guardó igual
    expect(payload['lat'], isNull); // sin latitud
    expect(payload['lng'], isNull); // sin longitud
  });

  test('deshacer Llegué borra la fila', () async {
    final actions = build(null); // las acciones
    final receipt = await actions.arrive(visitId: 101); // marca la llegada
    await actions.undo(receipt); // la deshace dentro de los 10 s
    expect(await db.select(db.outboxEvents).get(), isEmpty); // la cola queda vacía
  });
}