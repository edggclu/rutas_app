import 'dart:convert'; 
import 'dart:io'; 

import 'package:flutter_test/flutter_test.dart'; 
import 'package:telyser_app/domain/models/app_settings.dart'; 
import 'package:telyser_app/domain/models/enums.dart'; 
import 'package:telyser_app/domain/events/event_types.dart';
import 'package:telyser_app/domain/models/models.dart'; 
import 'package:telyser_app/domain/rules/no_answer.dart'; 
import 'package:telyser_app/domain/rules/visit_state.dart'; 

void main() {
  late AppSettings settings; // parámetros de prueba 10 min base + 1 min por km
  late Visit visit; // visita 102 , 5 km desde la anterior
  final arrived = DateTime.utc(2026, 10, 6, 20, 40); // hora de llegada de la prueba

  setUpAll(() { 
    settings = AppSettings.fromMap(json.decode( // lee settings.json y lo convierte en parámetros
        File('assets/mock/settings.json').readAsStringSync()) as Map<String, dynamic>); 
    final route = DayRoute.fromJson(json.decode( // lee my_day.json y lo convierte en ruta
        File('assets/mock/my_day.json').readAsStringSync()) as Map<String, dynamic>); 
    visit = route.visits[1].copyWith( // la segunda visita id 102
        status: VisitStatus.onSite, arrivedAt: arrived); 
  });

  VisitEvent ev(String type, {int visitId = 102}) => // atajo para crear acciones de la cola
      VisitEvent(type: type, visitId: visitId, occurredAt: arrived); 

  NoAnswerStatus statusAt(Duration after, List<VisitEvent> events) => // atajo estado X tiempo después de llegar
      computeNoAnswerStatus( 
          visit: visit, events: events, settings: settings, now: arrived.add(after));

  // prueba del cálculo de espera
  test('la espera es base + minutos por km', () { 
    expect(noAnswerWait(km: 5, settings: settings), const Duration(minutes: 15)); // 5 km - 15 min
    expect(noAnswerWait(km: 30, settings: settings), const Duration(minutes: 40)); // 30 km - 40 min
    expect(noAnswerWait(km: null, settings: settings), const Duration(minutes: 10)); // sin km - solo la base
    expect(noAnswerWait(km: 12.4, settings: settings), const Duration(minutes: 23)); // 22.4 se redondea hacia arriba
  });

  test('sin km de la visita anterior, usa la distancia estimada del lugar', () { // prueba del respaldo
    final raw = json.decode(File('assets/mock/my_day.json').readAsStringSync()) // lee el JSON
        as Map<String, dynamic>; // como mapa
    (raw['visits'] as List)[1]['km_from_previous'] = null; // borra el dato de la visita 102
    final v = DayRoute.fromJson(raw).visits[1]; // la visita sin km_from_previous
    expect(waitKm(v), 17.0); // usa estimated_km_from_office del lugar
  });

  test('al llegar, falta toda la espera y no puede irse', () { // estado inicial
    final s = statusAt(Duration.zero, const []); // justo al llegar, sin acciones
    expect(s.remaining, const Duration(minutes: 15)); // falta toda la espera
    expect(s.canLeave, isFalse); // no puede irse
  });

  test('la cuenta regresiva baja con el tiempo', () { // el tiempo corre
    final s = statusAt(const Duration(minutes: 5), const []); // 5 minutos después
    expect(s.remaining, const Duration(minutes: 10)); // faltan 10
  });

  test('con el tiempo cumplido pero sin contactar, no puede irse', () { // falta contacto
    final s = statusAt(const Duration(minutes: 16), const []); // 16 minutos después, sin acciones
    expect(s.timeDone, isTrue); // el tiempo ya se cumplió
    expect(s.remaining, Duration.zero); // lo que falta nunca es negativo
    expect(s.canLeave, isFalse); // pero faltan los contactos
  });

  test('contactos sin esperar el tiempo tampoco bastan', () { // falta tiempo
    final s = statusAt(const Duration(minutes: 1), [ // 1 minuto después
      ev(EventTypes.clientContacted), // ya contactó al cliente
      ev(EventTypes.officeCalled), // ya llamó a la oficina
    ]);
    expect(s.clientOk, isTrue); // cliente: cumplido
    expect(s.officeOk, isTrue); // oficina: cumplida
    expect(s.canLeave, isFalse); // pero el tiempo no
  });

  test('con las tres condiciones cumplidas, puede irse', () { // caso completo
    final s = statusAt(const Duration(minutes: 15), [ // justo al terminar la espera
      ev(EventTypes.clientContacted), // contactó al cliente
      ev(EventTypes.officeCalled), // llamó a la oficina
    ]);
    expect(s.canLeave, isTrue); // puede irse
  });

  test('falta una sola llamada y no puede irse', () { // las tres son necesarias
    final s = statusAt(const Duration(minutes: 20), [ // pasado el tiempo
      ev(EventTypes.clientContacted), // contactó al cliente
    ]); // pero no llamó a la oficina
    expect(s.officeOk, isFalse); // oficina: pendiente
    expect(s.canLeave, isFalse); // no puede irse
  });

  test('los contactos de otra visita no cuentan', () { // cada visita cuenta lo suyo
    final s = statusAt(const Duration(minutes: 20), [ // pasado el tiempo
      ev(EventTypes.clientContacted, visitId: 101), // contacto hecho en OTRA visita
      ev(EventTypes.officeCalled, visitId: 101), // llamada hecha en OTRA visita
    ]);
    expect(s.clientContacts, 0); // no cuenta
    expect(s.officeCalls, 0); // no cuenta
    expect(s.canLeave, isFalse); // no puede irse
  });
}