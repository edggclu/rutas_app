import 'package:flutter_test/flutter_test.dart'; // herramientas de prueba
import 'package:telyser_app/domain/closing.dart'; // lo que se prueba
import 'package:telyser_app/domain/event_types.dart'; // nombres de eventos
import 'package:telyser_app/domain/visit_state.dart'; // VisitEvent

void main() {
  final t0 = DateTime.utc(2026, 10, 6, 14, 20); // hora fija de prueba

  group('causas de garantía', () { // causas externas
    test('golpe y manipulación son externas; las demás no', () { // lista provisional
      expect(WarrantyCause.impact.isExternal, isTrue); // golpe
      expect(WarrantyCause.tampering.isExternal, isTrue); // manipulación
      expect(WarrantyCause.defect.isExternal, isFalse); // defecto
      expect(WarrantyCause.humiditySalt.isExternal, isFalse); // humedad o salitre
      expect(WarrantyCause.powerSurge.isExternal, isFalse); // variación eléctrica
      expect(WarrantyCause.unknown.isExternal, isFalse); // no se sabe
    });
  });

  group('canSaveWarranty', () { // requisitos del bloque de garantía
    test('necesita causa, foto de la falla y serial', () { // caso completo
      expect(canSaveWarranty(cause: WarrantyCause.defect, failurePhotos: 1, serial: 'SN123', serialPhotos: 0), isTrue); // todo
    });

    test('la etiqueta fotografiada sustituye al serial escrito', () { // alternativa
      expect(canSaveWarranty(cause: WarrantyCause.defect, failurePhotos: 1, serial: '', serialPhotos: 1), isTrue); // con foto de etiqueta
    });

    test('si falta algo, no se puede guardar', () { // cada requisito cuenta
      expect(canSaveWarranty(cause: null, failurePhotos: 1, serial: 'SN', serialPhotos: 0), isFalse); // sin causa
      expect(canSaveWarranty(cause: WarrantyCause.defect, failurePhotos: 0, serial: 'SN', serialPhotos: 0), isFalse); // sin foto
      expect(canSaveWarranty(cause: WarrantyCause.defect, failurePhotos: 1, serial: '  ', serialPhotos: 0), isFalse); // sin serial
    });
  });

  group('canContinueTomorrow', () { // requisitos de "Sigo otro día"
    test('"qué falta" es obligatorio', () { // texto vacío
      expect(canContinueTomorrow(missing: '', laidCable: false, cablingVideos: 0), isFalse); // vacío
      expect(canContinueTomorrow(missing: '  ', laidCable: false, cablingVideos: 0), isFalse); // solo espacios
      expect(canContinueTomorrow(missing: 'Cámaras del segundo piso', laidCable: false, cablingVideos: 0), isTrue); // con texto
    });

    test('si tendió cable, necesita el video', () { // regla del cableado
      expect(canContinueTomorrow(missing: 'x', laidCable: true, cablingVideos: 0), isFalse); // sin video
      expect(canContinueTomorrow(missing: 'x', laidCable: true, cablingVideos: 1), isTrue); // con video
    });
  });

  group('canSendBlocked', () { // requisitos de "No pude seguir"
    test('necesita motivo y nota', () { // básico
      expect(canSendBlocked(reason: null, incidentKind: null, note: 'x', damagePhotos: 0), isFalse); // sin motivo
      expect(canSendBlocked(reason: BlockReason.other, incidentKind: null, note: '', damagePhotos: 0), isFalse); // sin nota
      expect(canSendBlocked(reason: BlockReason.other, incidentKind: null, note: 'x', damagePhotos: 0), isTrue); // completo
    });

    test('un incidente exige su tipo', () { // subtipo obligatorio
      expect(canSendBlocked(reason: BlockReason.incident, incidentKind: null, note: 'x', damagePhotos: 0), isFalse); // sin tipo
    });

    test('daño a la propiedad exige fotos; un accidente no', () { // reglas distintas
      expect(canSendBlocked(reason: BlockReason.incident, incidentKind: IncidentKind.propertyDamage, note: 'x', damagePhotos: 0), isFalse); // sin foto
      expect(canSendBlocked(reason: BlockReason.incident, incidentKind: IncidentKind.propertyDamage, note: 'x', damagePhotos: 1), isTrue); // con foto
      expect(canSendBlocked(reason: BlockReason.incident, incidentKind: IncidentKind.accident, note: 'x', damagePhotos: 0), isTrue); // accidente sin foto
    });

    test('los seis motivos tienen código distinto', () { // sin repetidos
      expect(BlockReason.values.map((r) => r.code).toSet().length, 6); // seis códigos únicos
    });
  });

  group('garantía documentada', () { // lectura de la cola
    final events = [ // acciones de prueba
      VisitEvent(type: EventTypes.warrantyDocumented, visitId: 102, occurredAt: t0, payload: {'cause': 'defect'}), // primera
      VisitEvent(type: EventTypes.warrantyDocumented, visitId: 102, occurredAt: t0, payload: {'cause': 'impact'}), // la corrigió
    ];

    test('se detecta por visita', () { // filtra por visita
      expect(warrantyDocumented(events, 102), isTrue); // la 102 sí
      expect(warrantyDocumented(events, 101), isFalse); // la 101 no
    });

    test('la causa mostrada es la última guardada', () { // la más reciente gana
      expect(lastWarrantyCause(events, 102), WarrantyCause.impact); // golpe
      expect(lastWarrantyCause(events, 101), isNull); // sin garantía
    });
  });
}