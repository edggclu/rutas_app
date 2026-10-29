import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/domain/events/event_types.dart';
import 'package:telyser_app/domain/events/event_data.dart';
import 'package:telyser_app/domain/models/event_models.dart';
import 'package:telyser_app/domain/models/closing_models.dart';
import 'package:telyser_app/domain/models/extra_models.dart';
import 'package:telyser_app/domain/rules/visit_state.dart';

void main() {
  const item = ExtraItem( // un extra de ejemplo
    name: 'Cámara IP 4 MP',
    productId: 301,
    quantity: 1,
    unit: 'piece',
    source: ExtraSource.ownStock,
    reason: ExtraReason.clientAsked,
    requestedByAuthorized: true,
    requesterName: 'Sra. Lupita',
    notInstalled: false,
  );
  final itemMap = <String, dynamic>{ // el mapa que se guardaba antes para ese extra
    'name': 'Cámara IP 4 MP',
    'product_id': 301,
    'quantity': 1,
    'unit': 'piece',
    'source': 'own_stock',
    'reason': 'client_asked',
    'requested_by': 'authorized_contact',
    'requester_name': 'Sra. Lupita',
    'not_installed': false,
  };

  group('mismo JSON que antes', () { // lo que se guarda no cambió
    test('eventos sin datos', () { // llevan mapa vacío
      expect(const DepartureConfirmedEvent().toPayload(), isEmpty); // salida
      expect(const NoAnswerReportedEvent().toPayload(), isEmpty); // "No me abren"
      expect(const OfficeCalledEvent().toPayload(), isEmpty); // llamada a la oficina
      expect(const NoAnswerConfirmedEvent().toPayload(), isEmpty); // "No me atendieron"
      expect(const HelpRequestedEvent().toPayload(), isEmpty); // pidió ayuda
    });

    test('llegada y contacto', () { // con sus datos
      expect(
        const ArrivedEvent(mode: ArrivalMode.manual, lat: 20.7002, lng: -105.2943).toPayload(),
        {'mode': 'manual', 'lat': 20.7002, 'lng': -105.2943}, // igual que antes
      );
      expect(const ArrivedEvent(mode: ArrivalMode.manual).toPayload(), {'mode': 'manual', 'lat': null, 'lng': null}); // sin GPS
      expect(const ClientContactedEvent(ContactChannel.whatsapp).toPayload(), {'channel': 'whatsapp'}); // WhatsApp
    });

    test('faltantes', () { // renglones que faltan
      expect(
        const MissingItemsEvent([MissingItem(id: 4, text: 'Escalera de 6 m', kind: ChecklistKind.tool)]).toPayload(),
        {'items': [{'id': 4, 'text': 'Escalera de 6 m', 'kind': 'tool'}]}, // igual que antes
      );
    });

    test('terminé: sin extras vacío; con extras, quién confirmó', () { // dos variantes
      expect(const FinishedEvent().toPayload(), isEmpty); // sin extras
      expect(
        const FinishedEvent(confirmedBy: 'Ing. Ramírez', confirmedRole: 'Mantenimiento').toPayload(),
        {'extras_confirmed_by': 'Ing. Ramírez', 'extras_confirmed_role': 'Mantenimiento'}, // con extras
      );
      expect(const FinishedEvent(confirmedBy: 'Ing. Ramírez', confirmedRole: '').toPayload(), {'extras_confirmed_by': 'Ing. Ramírez'}); // cargo vacío se omite
    });

    test('extra y solicitudes', () { // las tres variantes de extras
      expect(const ExtraAddedEvent(item).toPayload(), itemMap); // el extra
      expect( // solicitud que nació de un extra
        const RequestAddedEvent(description: '1 x Cámara IP 4 MP', origin: RequestOrigin.creditHold, item: item).toPayload(),
        {...itemMap, 'description': '1 x Cámara IP 4 MP', 'origin': 'credit_hold'},
      );
      expect( // solicitud creada con "Solicitud después"
        const RequestAddedEvent(description: 'Cámaras en la alberca', origin: RequestOrigin.cannotDoNow, requestedByText: 'Gerente').toPayload(),
              {'description': 'Cámaras en la alberca', 'requester_text': 'Gerente', 'origin': 'cannot_do_now'},
      );
      expect( // aviso de retraso
        const RouteDelayReportedEvent(minutes: 120, extraName: 'Cámara IP 4 MP').toPayload(),
        {'minutes': 120, 'reason': 'extra', 'extra_name': 'Cámara IP 4 MP'},
      );
    });

    test('garantía, sigo otro día y no pude seguir', () { // cierre
      expect(
        const WarrantyDocumentedEvent(cause: WarrantyCause.humiditySalt, serial: 'SN-77').toPayload(),
        {'cause': 'humidity_salt', 'serial': 'SN-77'},
      );
      expect(
        const ContinueTomorrowEvent(
          materials: [MaterialUsed(id: 2, text: 'Cable UTP (m)', planned: 120, used: 70)],
          leftOnSite: 'Cámaras en el cuarto',
          missing: 'Cámaras del segundo piso',
          laidCable: true,
        ).toPayload(),
        {
          'materials_used': [{'id': 2, 'text': 'Cable UTP (m)', 'planned': 120, 'used': 70}],
          'left_on_site': 'Cámaras en el cuarto',
          'missing': 'Cámaras del segundo piso',
          'laid_cable': true,
        },
      );
      expect(
        const BlockedEvent(reason: BlockReason.incident, incidentKind: IncidentKind.accident, note: 'Se cayó').toPayload(),
        {'reason': 'incident', 'incident_kind': 'accident', 'note': 'Se cayó'},
      );
    });
  });

  group('ida y vuelta por la base', () { // se guarda como texto y se lee de vuelta
    final samples = <EventData>[ // un ejemplo de cada evento
      const DepartureConfirmedEvent(),
      const MissingItemsEvent([MissingItem(id: 4, text: 'Escalera', kind: ChecklistKind.tool)]),
      const ArrivedEvent(mode: ArrivalMode.manual, lat: 20.7, lng: -105.2),
      const NoAnswerReportedEvent(),
      const ClientContactedEvent(ContactChannel.call),
      const OfficeCalledEvent(),
      const NoAnswerConfirmedEvent(),
      const FinishedEvent(confirmedBy: 'Ing. Ramírez', confirmedRole: 'Mantenimiento'),
      const ExtraAddedEvent(item),
      const RequestAddedEvent(description: 'x', origin: RequestOrigin.otherPerson, item: item),
      const RequestAddedEvent(description: 'y', origin: RequestOrigin.cannotDoNow, requestedByText: 'Gerente'),
      const RouteDelayReportedEvent(minutes: 30, extraName: 'Cámara'),
      const WarrantyDocumentedEvent(cause: WarrantyCause.impact, serial: 'SN'),
      const ContinueTomorrowEvent(materials: [MaterialUsed(id: 1, text: 'Cable', planned: 10, used: 4)], leftOnSite: 'a', missing: 'b', laidCable: false),
      const BlockedEvent(reason: BlockReason.cannotSolve, note: 'No encuentro la falla'),
      const HelpRequestedEvent(),
      const NoteAddedEvent('Olvidé anotar el conector extra'),
    ];

    for (final s in samples) { // una prueba por evento
      test('${s.type} (${s.runtimeType})', () { // nombre de la prueba
        final stored = jsonDecode(jsonEncode(s.toPayload())) as Map<String, dynamic>; // como si pasara por la base
        final back = EventData.parse(s.type, stored); // se lee de vuelta
        expect(back.runtimeType, s.runtimeType); // misma clase
        expect(back.type, s.type); // mismo tipo
        expect(back.toPayload(), s.toPayload()); // mismos datos
      });
    }

    test('hay un ejemplo por cada tipo de EventTypes', () { // si agregas un evento y olvidas el ejemplo, falla
      expect(samples.map((s) => s.type).toSet().length, 16); // dieciséis tipos distintos
    });
  });

  group('lectura tolerante', () { // nunca se rompe la ruta
    test('un tipo desconocido se conserva tal cual', () { // versión más nueva de la app
      
      final d = EventData.parse('something_new', {'a': 1}); // tipo que no existe
      expect(d, isA<UnknownEvent>()); // se reconoce como desconocido
      expect(d.type, 'something_new'); // conserva el tipo
      expect(d.toPayload(), {'a': 1}); 
    });// conserva los datos
    test('una solicitud guardada con la llave vieja se sigue leyendo', () { // datos de prueba anteriores a este cambio
      final a = EventData.parse('request_added', {'description': 'x', 'requested_by': 'Gerente', 'origin': 'cannot_do_now'}); // llave vieja
      expect((a as RequestAddedEvent).requestedByText, 'Gerente'); // se lee igual
    });  


    test('un tipo conocido con datos vacíos usa valores por defecto', () { // no se pierde el cambio de estado
      expect(EventData.parse('blocked', {}), isA<BlockedEvent>()); // sigue siendo "no pude seguir"
      expect((EventData.parse('blocked', {}) as BlockedEvent).reason, BlockReason.other); // motivo por defecto
      expect((EventData.parse('arrived', {'mode': 5}) as ArrivedEvent).mode, ArrivalMode.manual); // dato de tipo equivocado: por defecto
    });
});

  group('VisitEvent', () { // une lo crudo con lo tipado
    final t0 = DateTime.utc(2026, 10, 6, 14, 20); // hora fija de prueba

    test('desde datos crudos se obtiene la clase tipada', () { // lo que hace el provider
      final e = VisitEvent(type: EventTypes.finished, visitId: 1, occurredAt: t0, payload: {'extras_confirmed_by': 'Ana'}); // fila de la base
      expect((e.data as FinishedEvent).confirmedBy, 'Ana'); // dato leído sin mapas
    });

    test('desde una clase tipada se obtienen los datos crudos', () { // lo que usan las pruebas nuevas
      final e = VisitEvent.of(const FinishedEvent(), visitId: 1, occurredAt: t0); // desde la clase
      expect(e.type, 'finished'); // tipo
      expect(e.payload, isEmpty); // datos
    });
  });
}