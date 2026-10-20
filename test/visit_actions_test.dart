import 'dart:convert'; 
import 'dart:io'; 

import 'package:drift/native.dart'; 
import 'package:flutter_test/flutter_test.dart'; 
import 'package:telyser_app/data/local/app_database.dart'; 
import 'package:telyser_app/data/local/outbox_repository.dart'; 
import 'package:telyser_app/data/location_service.dart'; 
import 'package:telyser_app/application/visit_actions.dart';
import 'package:telyser_app/domain/closing.dart'; 
import 'package:telyser_app/domain/event_types.dart';
import 'package:telyser_app/domain/extras.dart'; 
import 'package:telyser_app/domain/models.dart'; 

/// Ubicación falsa: devuelve siempre el punto que se le indique (o null).
class _FakeLocation implements LocationService { 
  _FakeLocation(this.point); 
  final GeoPoint? point; 
  @override
  Future<GeoPoint?> currentPosition() async => point; // devuelve el punto sin tocar el GPS
}

void main() {
  late AppDatabase db; // base en memoria
  late OutboxRepository outbox; // la cola
  late List<Visit> visits; // las visitas del JSON de prueba

  setUp(() { 
    db = AppDatabase.forTesting(NativeDatabase.memory()); // base nueva y vacía
    outbox = OutboxRepository(db, now: () => DateTime.utc(2026, 10, 6, 12)); // cola con reloj fijo
    final raw = File('assets/mock/my_day.json').readAsStringSync(); // lee el JSON de prueba
    visits = DayRoute.fromJson(json.decode(raw) as Map<String, dynamic>).visits; // lo convierte en visitas
  });

  tearDown(() => db.close()); 

  VisitActions build(GeoPoint? point) => 
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

    test('No me abren avisa una sola vez por visita', () async { // no duplica el aviso
    final actions = build(null); // las acciones
    await actions.reportNoAnswer(visitId: 102); // primer toque
    await actions.reportNoAnswer(visitId: 102); // segundo toque (el técnico volvió a entrar)
    final rows = await db.select(db.outboxEvents).get(); // lee la cola
    expect(rows.length, 1); // solo hay un aviso
    expect(rows.single.type, EventTypes.noAnswerReported); // del tipo correcto
  });

  test('registrar contacto con el cliente guarda el canal', () async { // llamada o WhatsApp
    await build(null).registerClientContact(visitId: 102, channel: 'whatsapp'); // toca WhatsApp
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    expect(row.type, EventTypes.clientContacted); // tipo correcto
    expect(jsonDecode(row.payloadJson)['channel'], 'whatsapp'); // guardó el canal
  });

  test('registrar llamada a la oficina guarda el evento', () async { // llamada a la oficina
    await build(null).registerOfficeCall(visitId: 102); // toca llamar a la oficina
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    expect(row.type, EventTypes.officeCalled); // tipo correcto
    expect(row.visitId, 102); // de la visita correcta
  });

  test('No me atendieron queda en gracia y se puede deshacer', () async { // el cierre es deslizable
    final actions = build(null); // las acciones
    final receipt = await actions.confirmNoAnswer(visitId: 102); // desliza
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    expect(row.type, EventTypes.noAnswerConfirmed); // tipo correcto
    expect(row.state, 'grace'); // en tiempo de gracia
    await actions.undo(receipt); // deshace
    expect(await db.select(db.outboxEvents).get(), isEmpty); // la cola queda vacía
  });

    test('Terminé el trabajo queda en gracia y se puede deshacer', () async { // cierre simple
    final actions = build(null); // las acciones
    final receipt = await actions.finish(visitId: 101); // desliza "Terminé"
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    expect(row.type, EventTypes.finished); // tipo correcto
    expect(row.visitId, 101); // visita correcta
    expect(row.state, 'grace'); // en tiempo de gracia
    await actions.undo(receipt); // deshace
    expect(await db.select(db.outboxEvents).get(), isEmpty); // la cola queda vacía
  });

    ExtraDraft draft({bool authorized = true, bool equipment = true, bool notInstalled = false, int? delay}) => // atajo para armar el borrador
      ExtraDraft( // un extra de prueba
        name: 'Cámara IP 4 MP', // nombre
        productId: 301, // id del catálogo
        quantity: 1, // cantidad
        unit: 'piece', // unidad
        source: ExtraSource.ownStock, // salió de su material
        reason: ExtraReason.clientAsked, // lo pidió el cliente
        requestedByAuthorized: authorized, // quién lo pidió
        isEquipment: equipment, // ¿es equipo?
        notInstalled: notInstalled, // ¿no se instaló?
        delayMinutes: delay, // retraso
      );

  test('un extra normal se guarda como extra_added con sus datos', () async { // caso normal
    final r = await build(null).addExtra(visit: visits[1], draft: draft()); // la visita 102 (cliente al corriente)
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    final p = jsonDecode(row.payloadJson) as Map<String, dynamic>; // sus datos

    expect(r.outcome, ExtraOutcome.register); // se registró
    expect(row.type, EventTypes.extraAdded); // tipo correcto
    expect(row.state, 'grace'); // con tiempo para deshacer
    expect(p['name'], 'Cámara IP 4 MP'); // nombre guardado
    expect(p['source'], 'own_stock'); // origen guardado
    expect(p['requested_by'], 'authorized_contact'); // lo pidió el contacto autorizado
    expect(p['requester_name'], 'Sra. Lupita'); // con su nombre
  });

  test('si lo pide otra persona, solo queda la solicitud', () async { // regla 1
    final r = await build(null).addExtra(visit: visits[1], draft: draft(authorized: false)); // otra persona
    final rows = await db.select(db.outboxEvents).get(); // la cola
    expect(r.outcome, ExtraOutcome.laterOtherPerson); // quedó como solicitud
    expect(rows.map((e) => e.type), [EventTypes.requestAdded]); // no hay extra_added
    expect(jsonDecode(rows.single.payloadJson)['origin'], 'other_person'); // origen correcto
  });

  test('saldo vencido y equipo: queda como solicitud por saldo', () async { // regla 2
    final r = await build(null).addExtra(visit: visits[0], draft: draft()); // la visita 101 (Hotel Bahía, saldo vencido)
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    expect(r.outcome, ExtraOutcome.laterCreditHold); // quedó como solicitud
    expect(row.type, EventTypes.requestAdded); // tipo correcto
    expect(jsonDecode(row.payloadJson)['origin'], 'credit_hold'); // origen correcto
  });

  test('saldo vencido pero material (no equipo): se registra', () async { // cable, conectores...
    final r = await build(null).addExtra(visit: visits[0], draft: draft(equipment: false)); // no es equipo
    expect(r.outcome, ExtraOutcome.register); // se hace
  });

  test('si retrasa las visitas, también avisa al jefe', () async { // regla del retraso
    await build(null).addExtra(visit: visits[1], draft: draft(delay: 120)); // retrasa 2 horas
    final rows = await db.select(db.outboxEvents).get(); // la cola
    expect(rows.map((e) => e.type), [EventTypes.extraAdded, EventTypes.routeDelayReported]); // extra y aviso
    expect(jsonDecode(rows.last.payloadJson)['minutes'], 120); // minutos guardados
  });

  test('si el extra no se hace, no se avisa de retraso', () async { // no hay retraso si no se hizo
    await build(null).addExtra(visit: visits[1], draft: draft(authorized: false, delay: 120)); // otra persona
    final rows = await db.select(db.outboxEvents).get(); // la cola
    expect(rows.map((e) => e.type), [EventTypes.requestAdded]); // solo la solicitud
  });

  test('deshacer un extra con retraso borra los dos eventos', () async { // el comprobante cubre todo
    final actions = build(null); // las acciones
    final r = await actions.addExtra(visit: visits[1], draft: draft(delay: 60)); // extra con retraso
    await actions.undo(r.receipt); // deshace
    expect(await db.select(db.outboxEvents).get(), isEmpty); // la cola queda vacía
  });

  test('una solicitud para después guarda su descripción y origen', () async { // botón "Solicitud después"
    await build(null).addRequest( // guarda una solicitud
        visitId: 101, description: 'Cámaras en la alberca', requestedBy: 'Gerente'); // con quién la pidió
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    final p = jsonDecode(row.payloadJson) as Map<String, dynamic>; // sus datos
    expect(row.type, EventTypes.requestAdded); // tipo correcto
    expect(p['description'], 'Cámaras en la alberca'); // descripción
    expect(p['origin'], 'cannot_do_now'); // origen
    expect(p['requested_by'], 'Gerente'); // quién la pidió
  });

    test('Terminé con extras guarda quién los confirmó', () async { // confirmación de extras
    await build(null).finish(visitId: 102, confirmedBy: 'Ing. Ramírez', confirmedRole: 'Mantenimiento'); // cierra con confirmación
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    final p = jsonDecode(row.payloadJson) as Map<String, dynamic>; // sus datos
    expect(row.type, EventTypes.finished); // tipo correcto
    expect(p['extras_confirmed_by'], 'Ing. Ramírez'); // quién confirmó
    expect(p['extras_confirmed_role'], 'Mantenimiento'); // su cargo
  });

  test('Terminé sin extras no lleva datos de confirmación', () async { // cierre simple
    await build(null).finish(visitId: 102); // cierra sin confirmación
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    expect(jsonDecode(row.payloadJson), isEmpty); // sin datos extra
  });

  test('documentar la garantía guarda causa y serial', () async { // bloque de garantía
    await build(null).documentWarranty(visitId: 102, cause: WarrantyCause.humiditySalt, serial: 'SN-77'); // documenta
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    final p = jsonDecode(row.payloadJson) as Map<String, dynamic>; // sus datos
    expect(row.type, EventTypes.warrantyDocumented); // tipo correcto
    expect(p['cause'], 'humidity_salt'); // causa guardada
    expect(p['serial'], 'SN-77'); // serial guardado
  });

  test('Sigo otro día guarda material, lo que falta y el cableado', () async { // C7a
    final receipt = await build(null).continueTomorrow( // marca sigo otro día
      visitId: 101, // visita
      materials: const [MaterialUsed(id: 2, text: 'Cable UTP (m)', planned: 120, used: 70)], // 70 de 120 m
      leftOnSite: 'Cámaras en el cuarto de mantenimiento', // lo que se queda
      missing: '  Cámaras del segundo piso ', // lo que falta (con espacios)
      laidCable: true, // tendió cable
    );
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    final p = jsonDecode(row.payloadJson) as Map<String, dynamic>; // sus datos
    expect(row.type, EventTypes.continueTomorrow); // tipo correcto
    expect(row.state, 'grace'); // con tiempo para deshacer
    expect(p['materials_used'][0]['used'], 70); // lo usado
    expect(p['materials_used'][0]['planned'], 120); // lo planeado
    expect(p['missing'], 'Cámaras del segundo piso'); // sin espacios sobrantes
    expect(p['laid_cable'], isTrue); // tendió cable
    expect(receipt.uuids, [row.uuid]); // el comprobante apunta a esa fila
  });

  test('No pude seguir guarda motivo, tipo de incidente y nota', () async { // C7b
    await build(null).blockVisit( // marca no pude seguir
      visitId: 101, // visita
      reason: BlockReason.incident, // incidente
      incidentKind: IncidentKind.accident, // accidente
      note: ' Se cayó de la escalera ', // nota (con espacios)
    );
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    final p = jsonDecode(row.payloadJson) as Map<String, dynamic>; // sus datos
    expect(row.type, EventTypes.blocked); // tipo correcto
    expect(p['reason'], 'incident'); // motivo
    expect(p['incident_kind'], 'accident'); // tipo de incidente
    expect(p['note'], 'Se cayó de la escalera'); // nota sin espacios sobrantes
  });

  test('pedir ayuda al ingeniero se registra sin tiempo de deshacer', () async { // botón normal
    await build(null).requestHelp(visitId: 101); // pide ayuda
    final row = (await db.select(db.outboxEvents).get()).single; // la única fila
    expect(row.type, EventTypes.helpRequested); // tipo correcto
    expect(row.visitId, 101); // visita correcta
  });
}