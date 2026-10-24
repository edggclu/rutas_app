import 'package:flutter_test/flutter_test.dart'; // herramientas de prueba
import 'package:telyser_app/application/plan_actions.dart'; // lo que se prueba
import 'package:telyser_app/data/repositories.dart'; // PlanRepository
import 'package:telyser_app/domain/models/enums.dart'; // ChecklistKind
import 'package:telyser_app/domain/models/models.dart'; // Plan
import 'package:telyser_app/domain/plan_rules.dart'; // las reglas

/// Repositorio falso: guarda lo último que recibió.
class _FakeRepo implements PlanRepository {
  int? jobId;
  Plan? saved;

  @override
  Future<Plan> save(int jobId, Plan plan) async {
    this.jobId = jobId;
    saved = plan;
    return plan;
  }
}

Plan _plan({String text = 'Cámaras IP', num? qty = 8, String label = 'C1'}) => Plan(
      notes: 'Cable por el plafón',
      items: [ChecklistItem(id: 1, kind: ChecklistKind.material, text: text, quantity: qty)],
      sketch: Sketch(image: 'x.png', aspectRatio: 1.5, pins: [SketchPin(id: 1, label: label, x: 0.1, y: 0.2)]),
    );

void main() {
  test('un plan completo se puede guardar', () => expect(canSavePlan(_plan()), isTrue));

  test('no se guarda con un renglón sin nombre', () => expect(canSavePlan(_plan(text: '  ')), isFalse));

  test('no se guarda sin cantidad ni con cantidad cero o negativa', () {
    expect(canSavePlan(_plan(qty: 0)), isFalse);
    expect(canSavePlan(_plan(qty: -2)), isFalse);
    expect(canSavePlan(_plan(qty: null)), isFalse); // todo renglón lleva cantidad
  });

  test('no se guarda con un pin sin etiqueta', () => expect(canSavePlan(_plan(label: '')), isFalse));

  test('el siguiente id es mayor que todos los que hay', () {
    expect(nextLocalId(const []), 1);
    expect(nextLocalId([3, 1, 7]), 8);
  });

  test('toJson y fromJson dan el mismo plan', () {
    final again = Plan.fromJson(_plan().toJson());
    expect(again.notes, 'Cable por el plafón');
    expect(again.items.single.kind, ChecklistKind.material);
    expect(again.items.single.quantity, 8);
    expect(again.sketch!.pins.single.label, 'C1');
  });

  test('guardar manda el plan al repositorio y avisa', () async {
    final repo = _FakeRepo();
    var changes = 0;
    await PlanActions(repo, onChanged: () => changes++).save(17, _plan());
    expect(repo.jobId, 17);
    expect(repo.saved!.items.length, 1);
    expect(changes, 1);
  });

  test('un plan inválido no llega al repositorio', () async {
    final repo = _FakeRepo();
    var changes = 0;
    await expectLater(PlanActions(repo, onChanged: () => changes++).save(17, _plan(text: '')), throwsArgumentError);
    expect(repo.saved, isNull);
    expect(changes, 0);
  });
}
