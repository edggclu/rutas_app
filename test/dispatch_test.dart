import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/domain/models/dispatch_models.dart';
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/domain/rules/technician_state.dart';

void main() {
  late DispatchBoard board;

  setUp(() {
    board = DispatchBoard.fromJson(json.decode(File('assets/mock/dispatch.json').readAsStringSync()) as Map<String, dynamic>);
  });

  test('dispatch.json trae las cuatro secciones', () {
    expect(board.decisions.length, 6);
    expect(board.today.map((t) => t.name), ['Pedro', 'Luis', 'Marco']);
    expect(board.tomorrow.length, 2);
    expect(board.unassigned.length, 3);
  });

  test('las urgencias van arriba y lo demás de lo más nuevo a lo más viejo', () {
    expect(board.decisions.first.kind, DecisionKind.urgent);
    final rest = board.decisions.skip(1).map((d) => d.createdAt).toList();
    expect(rest, [...rest]..sort((a, b) => b.compareTo(a)));
  });

  test('un tipo de decisión desconocido se lee como otro', () {
    expect(DecisionKind.parse('algo_nuevo'), DecisionKind.other);
    expect(DecisionKind.parse(null), DecisionKind.other);
    expect(Decision.fromJson({'kind': 'raro', 'title': 'x'}).kind, DecisionKind.other);
  });

  test('el estado de cada técnico sale de sus visitas', () {
    TechnicianState stateOf(TechnicianRoute t) =>
        technicianStateOf([for (final v in t.visits) (status: v.status, client: v.clientName)]);
    expect(stateOf(board.today[0]).label, 'En sitio en Condominio Las Palmas'); // Pedro
    expect(stateOf(board.today[1]).label, 'En camino a Hotel Costa Azul'); // Luis
    expect(stateOf(board.today[2]).label, 'Libre'); // Marco, sin visitas
  });

  test('el semáforo trae las cinco luces y el servidor dice si se puede programar', () {
    final ready = board.unassigned[0];
    expect(ready.lights.length, 5);
    expect(ready.lights[Light.material], LightState.warning);
    expect(ready.canSchedule, isTrue);

    final deposit = board.unassigned[1]; // anticipo en rojo
    expect(deposit.lights[Light.deposit], LightState.blocked);
    expect(deposit.canSchedule, isFalse);
  });

  test('si el servidor no manda can_schedule, solo bloquea una luz en rojo', () {
    final noFlag = board.unassigned[2]; // adeudo en ámbar, sin can_schedule
    expect(noFlag.lights[Light.balance], LightState.warning);
    expect(noFlag.canSchedule, isTrue);
    final blocked = UnassignedJob.fromJson({
      'id': 1,
      'lights': {'deposit_paid': 'blocked'},
    });
    expect(blocked.canSchedule, isFalse);
  });

  test('una luz que falta o es desconocida queda pendiente', () {
    final job = UnassignedJob.fromJson({'id': 1, 'lights': {'access': 'raro'}});
    expect(job.lights[Light.access], LightState.warning);
    expect(job.lights[Light.confirmed], LightState.warning); // no vino
  });

  test('una visita de Pedro cerrada sin terminar conserva su resultado y el día', () {
    final v = board.today[0].visits[0];
    expect(v.status, VisitStatus.done);
    expect(v.result, VisitResult.continueLater);
    expect(v.dayNumber, 1);
  });

  test('un tablero vacío o con secciones raras no rompe la lectura', () {
    final empty = DispatchBoard.fromJson({'today': 5, 'decisions': 'x'});
    expect(empty.decisions, isEmpty);
    expect(empty.today, isEmpty);
    expect(empty.unassigned, isEmpty);
  });
}
