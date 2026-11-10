import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/application/dispatch_actions.dart';
import 'package:telyser_app/data/mock/mock_repositories.dart';
import 'package:telyser_app/data/repositories.dart';
import 'package:telyser_app/domain/dispatch_rules.dart';
import 'package:telyser_app/domain/models/dispatch_models.dart';
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/domain/session_errors.dart';

final _today = DateTime(2026, 10, 29);

UnassignedJob _job({bool ready = true}) => UnassignedJob.fromJson({
      'id': 42,
      'client': 'Colegio Horizonte',
      'lights': {'deposit_paid': ready ? 'ok' : 'blocked'},
    });

DispatchVisit _visit({String status = 'pending'}) =>
    DispatchVisit.fromJson({'id': 102, 'status': status, 'client': 'Mar Azul'});

/// Repositorio falso: anota lo que se le pidió y puede responder que algo ya cambió.
class _FakeRepo implements DispatchRepository {
  _FakeRepo({this.conflict = false});

  final bool conflict;
  final created = <NewVisit>[];
  final moved = <({int id, DateTime? date, int? tech})>[];

  @override
  Future<DispatchBoard> fetch() => throw UnimplementedError();

  @override
  Future<void> createVisit(NewVisit visit) async {
    if (conflict) throw const ConflictException();
    created.add(visit);
  }

  @override
  Future<void> moveVisit({required int visitId, DateTime? date, int? technicianId}) async {
    if (conflict) throw const ConflictException();
    moved.add((id: visitId, date: date, tech: technicianId));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // el mock lee assets/

  group('reglas', () {
    test('solo cuenta el día', () => expect(dateOnly(DateTime(2026, 10, 29, 18, 45)), DateTime(2026, 10, 29)));

    test('programar: sin problemas con un trabajo listo, técnico y fecha de hoy o futura', () {
      expect(checkSchedule(job: _job(), technicianId: 7, date: _today, today: _today), isNull);
      expect(checkSchedule(job: _job(), technicianId: 7, date: DateTime(2026, 11, 3), today: _today), isNull);
    });

    test('programar: un trabajo con una luz en rojo no se puede', () {
      expect(checkSchedule(job: _job(ready: false), technicianId: 7, date: _today, today: _today),
          ScheduleIssue.jobNotReady);
    });

    test('programar: falta el técnico, fecha pasada o acompañante que es el mismo responsable', () {
      expect(checkSchedule(job: _job(), technicianId: null, date: _today, today: _today), ScheduleIssue.noTechnician);
      expect(checkSchedule(job: _job(), technicianId: 7, date: DateTime(2026, 10, 28), today: _today),
          ScheduleIssue.pastDate);
      expect(checkSchedule(job: _job(), technicianId: 7, date: _today, today: _today, companionIds: {7}),
          ScheduleIssue.companionIsResponsible);
    });

    test('mover: solo una visita que no ha empezado', () {
      expect(canMoveVisit(_visit()), isTrue);
      expect(canMoveVisit(_visit(status: 'en_route')), isFalse);
      expect(canMoveVisit(_visit(status: 'on_site')), isFalse);
      expect(canMoveVisit(_visit(status: 'done')), isFalse);
    });

    test('mover: debe cambiar algo, y no a un día pasado', () {
      MoveIssue? check({DateTime? to, int tech = 7, String status = 'pending'}) => checkMove(
            visit: _visit(status: status),
            fromDate: _today,
            fromTechnicianId: 7,
            toDate: to ?? _today,
            toTechnicianId: tech,
            today: _today,
          );
      expect(check(), MoveIssue.nothingChanged);
      expect(check(tech: 8), isNull); // otro técnico, el mismo día
      expect(check(to: DateTime(2026, 10, 30)), isNull); // el mismo técnico, otro día
      expect(check(to: DateTime(2026, 10, 28), tech: 8), MoveIssue.pastDate);
      expect(check(tech: 8, status: 'on_site'), MoveIssue.notMovable);
    });
  });

  group('acciones', () {
    test('programar manda la visita al servidor, con el día sin hora, y avisa', () async {
      final repo = _FakeRepo();
      var changes = 0;
      await DispatchActions(repo, onChanged: () => changes++, now: () => _today).scheduleVisit(
        job: _job(),
        date: DateTime(2026, 10, 30, 16, 20),
        technicianId: 7,
        companionIds: {9, 8},
        urgent: true,
      );
      final v = repo.created.single;
      expect(v.jobId, 42);
      expect(v.date, DateTime(2026, 10, 30));
      expect(v.companionIds, [8, 9]); // ordenados
      expect(v.urgent, isTrue);
      expect(changes, 1);
    });

    test('un trabajo que no está listo no llega al servidor', () async {
      final repo = _FakeRepo();
      var changes = 0;
      await expectLater(
        DispatchActions(repo, onChanged: () => changes++, now: () => _today)
            .scheduleVisit(job: _job(ready: false), date: _today, technicianId: 7),
        throwsArgumentError,
      );
      expect(repo.created, isEmpty);
      expect(changes, 0);
    });

    test('mover solo manda lo que cambió', () async {
      final repo = _FakeRepo();
      final actions = DispatchActions(repo, onChanged: () {}, now: () => _today);
      await actions.moveVisit(visit: _visit(), fromDate: _today, fromTechnicianId: 7, toDate: _today, toTechnicianId: 8);
      await actions.moveVisit(
          visit: _visit(), fromDate: _today, fromTechnicianId: 7, toDate: DateTime(2026, 10, 30), toTechnicianId: 7);
      expect(repo.moved[0], (id: 102, date: null, tech: 8)); // solo el técnico
      expect(repo.moved[1], (id: 102, date: DateTime(2026, 10, 30), tech: null)); // solo el día
    });

    test('si el servidor dice que ya cambió, se vuelve a pedir la lista y el error sigue', () async {
      var changes = 0;
      final actions = DispatchActions(_FakeRepo(conflict: true), onChanged: () => changes++, now: () => _today);
      await expectLater(
          actions.scheduleVisit(job: _job(), date: _today, technicianId: 7), throwsA(isA<ConflictException>()));
      await expectLater(
        actions.moveVisit(visit: _visit(), fromDate: _today, fromTechnicianId: 7, toDate: _today, toTechnicianId: 8),
        throwsA(isA<ConflictException>()),
      );
      expect(changes, 2); // las dos veces refresca
    });
  });

  group('repositorio de prueba', () {
    late MockDispatchRepository repo;

    setUp(() => repo = MockDispatchRepository(now: () => _today));

    Future<DispatchBoard> board() => repo.fetch();
    TechnicianRoute route(DispatchBoard b, int id, {bool tomorrow = false}) =>
        (tomorrow ? b.tomorrow : b.today).firstWhere((t) => t.id == id);

    test('programar para hoy lo quita de Por asignar y lo agrega a la ruta de ese técnico', () async {
      final before = await board();
      expect(before.unassigned.any((j) => j.id == 41), isTrue);
      await repo.createVisit(NewVisit(jobId: 41, date: _today, technicianId: 9)); // Marco, que no tenía visitas
      final after = await board();
      expect(after.unassigned.any((j) => j.id == 41), isFalse);
      expect(route(after, 9).visits.single.clientName, 'Clínica Santa Fe');
      expect(route(after, 9).visits.single.status, VisitStatus.pending);
    });

    test('programar para mañana a un técnico sin ruta ese día le crea su ruta', () async {
      await repo.createVisit(NewVisit(jobId: 41, date: DateTime(2026, 10, 30), technicianId: 9));
      expect(route(await board(), 9, tomorrow: true).visits.length, 1);
    });

    test('programar una urgencia quita la decisión que la pedía', () async {
      final before = await board();
      expect(before.decisions.any((d) => d.kind == DecisionKind.urgent && d.jobId == 43), isTrue);
      await repo.createVisit(NewVisit(jobId: 43, date: _today, technicianId: 8, urgent: true));
      expect((await board()).decisions.any((d) => d.kind == DecisionKind.urgent), isFalse);
    });

    test('un trabajo que ya se programó da conflicto', () async {
      await repo.createVisit(NewVisit(jobId: 41, date: _today, technicianId: 8));
      await expectLater(
          repo.createVisit(NewVisit(jobId: 41, date: _today, technicianId: 9)), throwsA(isA<ConflictException>()));
    });

    test('mover a otro técnico la saca de una ruta y la pone en la otra', () async {
      await repo.moveVisit(visitId: 102, technicianId: 9);
      final b = await board();
      expect(route(b, 7).visits.any((v) => v.id == 102), isFalse);
      expect(route(b, 9).visits.single.id, 102);
    });

    test('mover a mañana la pasa a la lista de mañana, con el mismo técnico', () async {
      await repo.moveVisit(visitId: 102, date: DateTime(2026, 10, 30));
      final b = await board();
      expect(route(b, 7).visits.any((v) => v.id == 102), isFalse);
      expect(route(b, 7, tomorrow: true).visits.any((v) => v.id == 102), isTrue);
    });

    test('una visita que ya empezó no se mueve', () async {
      await expectLater(
          repo.moveVisit(visitId: 103, technicianId: 9), throwsA(isA<ConflictException>())); // Pedro ya está en sitio
    });

    test('una visita que no existe da conflicto', () async {
      await expectLater(repo.moveVisit(visitId: 999, technicianId: 9), throwsA(isA<ConflictException>()));
    });
  });
}
