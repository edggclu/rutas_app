import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/events/event_data.dart';
import 'package:telyser_app/domain/models/closing_models.dart';
import 'package:telyser_app/domain/models/extra_models.dart';
import 'package:telyser_app/domain/rules/visit_state.dart';
import 'package:telyser_app/domain/rules/visit_summary.dart';

final _t = DateTime.utc(2026, 10, 6, 15);

VisitEvent _e(EventData d, {int visit = 101, int minutes = 0}) =>
    VisitEvent.of(d, occurredAt: _t.add(Duration(minutes: minutes)), visitId: visit);

const _item = ExtraItem(
  name: 'Conector RJ45',
  quantity: 3,
  source: ExtraSource.ownStock,
  reason: ExtraReason.clientAsked,
  requestedByAuthorized: true,
  notInstalled: false,
);

void main() {
  test('junta extras, solicitudes, garantía, cierre y notas de la visita', () {
    final s = summarizeVisit([
      _e(const ExtraAddedEvent(_item)),
      _e(const RequestAddedEvent(description: 'Cámara en la alberca', origin: RequestOrigin.cannotDoNow), minutes: 1),
      _e(const WarrantyDocumentedEvent(cause: WarrantyCause.impact, serial: 'SN-1'), minutes: 2),
      _e(const FinishedEvent(confirmedBy: 'Ing. Ramírez'), minutes: 3),
      _e(const NoteAddedEvent('  Olvidé anotar el cable sobrante  '), minutes: 60),
    ], 101);
    expect(s.extras.single.name, 'Conector RJ45');
    expect(s.requests.single.description, 'Cámara en la alberca');
    expect(s.warranty!.serial, 'SN-1');
    expect((s.closing as FinishedEvent).confirmedBy, 'Ing. Ramírez');
    expect(s.notes.single.text, 'Olvidé anotar el cable sobrante'); // sin espacios sobrantes
    expect(s.notes.single.at, _t.add(const Duration(minutes: 60)));
  });

  test('ignora lo de otras visitas', () {
    final s = summarizeVisit([
      _e(const ExtraAddedEvent(_item), visit: 102),
      _e(const NoteAddedEvent('de otra visita'), visit: 102),
      _e(const FinishedEvent(), visit: 102),
    ], 101);
    expect(s.extras, isEmpty);
    expect(s.notes, isEmpty);
    expect(s.closing, isNull);
  });

  test('las notas salen en el orden en que se escribieron y las vacías no cuentan', () {
    final s = summarizeVisit([
      _e(const NoteAddedEvent('primera')),
      _e(const NoteAddedEvent('   ')),
      _e(const NoteAddedEvent('segunda'), minutes: 5),
    ], 101);
    expect(s.notes.map((n) => n.text), ['primera', 'segunda']);
  });

  test('el cierre es el último que cerró la visita', () {
    final s = summarizeVisit([
      _e(const ContinueTomorrowEvent(materials: [], leftOnSite: 'a', missing: 'b', laidCable: false)),
      _e(const BlockedEvent(reason: BlockReason.cannotSolve, note: 'x'), minutes: 5),
    ], 101);
    expect(s.closing, isA<BlockedEvent>());
  });

  test('una nota vacía no se puede agregar', () {
    expect(canAddNote(''), isFalse);
    expect(canAddNote('   '), isFalse);
    expect(canAddNote('algo'), isTrue);
  });
}
