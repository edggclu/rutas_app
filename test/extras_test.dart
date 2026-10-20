import 'package:flutter_test/flutter_test.dart'; // herramientas de prueba
import 'package:telyser_app/domain/event_types.dart'; // nombres de eventos
import 'package:telyser_app/domain/extras.dart'; // lo que se prueba
import 'package:telyser_app/domain/visit_state.dart'; // VisitEvent

void main() {
  final t0 = DateTime.utc(2026, 10, 6, 14, 20); // hora fija de prueba

  ExtraOutcome decide({ // atajo: aplica las reglas con valores por defecto "normales"
    bool authorized = true, // lo pidió el contacto autorizado
    bool overdue = false, // cliente al corriente
    bool equipment = true, // es equipo
    bool notInstalled = false, // se instaló
  }) =>
      decideExtra( // aplica las reglas
          requestedByAuthorized: authorized,
          clientOverdue: overdue,
          isEquipment: equipment,
          notInstalled: notInstalled);

  group('decideExtra', () { // reglas del documento
    test('contacto autorizado y cliente al corriente: se registra', () { // caso normal
      expect(decide(), ExtraOutcome.register); // se hace
    });

    test('lo pide otra persona: queda como solicitud', () { // regla 1
      expect(decide(authorized: false), ExtraOutcome.laterOtherPerson); // no se hace
    });

    test('saldo vencido y equipo: queda como solicitud', () { // regla 2
      expect(decide(overdue: true), ExtraOutcome.laterCreditHold); // no se hace
    });

    test('saldo vencido pero no es equipo: se registra', () { // cable, servicios...
      expect(decide(overdue: true, equipment: false), ExtraOutcome.register); // se hace
    });

    test('saldo vencido pero es una nota de "no se instaló": se registra', () { // no se agrega equipo
      expect(decide(overdue: true, notInstalled: true), ExtraOutcome.register); // se anota
    });

    test('otra persona gana aunque también haya saldo vencido', () { // el orden importa
      expect(decide(authorized: false, overdue: true), ExtraOutcome.laterOtherPerson); // regla 1 primero
    });
  });

  group('extrasOf y requestsOf', () { // lectura de la cola
    final events = [ // acciones de prueba
      VisitEvent( // extra de la visita 101
        type: EventTypes.extraAdded,
        visitId: 101,
        occurredAt: t0,
        payload: {'name': 'Cámara IP 4 MP', 'quantity': 1, 'not_installed': false},
      ),
      VisitEvent( // extra "no se instaló" de la visita 101
        type: EventTypes.extraAdded,
        visitId: 101,
        occurredAt: t0,
        payload: {'name': 'Cámara del pasillo', 'quantity': 1, 'not_installed': true},
      ),
      VisitEvent( // extra de OTRA visita
        type: EventTypes.extraAdded,
        visitId: 102,
        occurredAt: t0,
        payload: {'name': 'Conector RJ45', 'quantity': 3},
      ),
      VisitEvent( // solicitud de la visita 101
        type: EventTypes.requestAdded,
        visitId: 101,
        occurredAt: t0,
        payload: {'description': 'Cámaras en la alberca', 'origin': 'cannot_do_now'},
      ),
    ];

    test('solo toma los extras de la visita pedida', () { // filtra por visita
      final x = extrasOf(events, 101); // extras de la 101
      expect(x.length, 2); // dos extras
      expect(x.first.label, '1 × Cámara IP 4 MP'); // texto del primero
      expect(x.last.notInstalled, isTrue); // el segundo es "no se instaló"
    });

    test('las cantidades enteras no llevan decimales', () { // 3.0 -> 3
      expect(quantityText(3.0), '3'); // entera
      expect(quantityText(1.5), '1.5'); // con decimales
    });

    test('las solicitudes se leen con su origen', () { // lectura de solicitudes
      final r = requestsOf(events, 101); // solicitudes de la 101
      expect(r.single.description, 'Cámaras en la alberca'); // descripción
      expect(r.single.origin, RequestOrigin.cannotDoNow); // origen (ahora es un enum, no un texto)
      expect(requestsOf(events, 102), isEmpty); // la 102 no tiene
    });
  });
}