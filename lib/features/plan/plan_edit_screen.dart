import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/input_formatters.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/unsaved_guard.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../../domain/plan_rules.dart';
import '../../providers/plan_providers.dart';
import 'widgets/sketch_editor.dart';

/// D2 · Editar el plan del trabajo (ingeniero): notas, material, herramienta y pines del croquis.
/// Guarda todo junto con el botón de abajo; mientras tanto los cambios viven solo en esta pantalla.
class PlanEditScreen extends ConsumerStatefulWidget {
  const PlanEditScreen({super.key, required this.jobId, required this.folio, this.plan});

  final int jobId;
  final String folio;
  final Plan? plan; // null = el trabajo todavía no tiene plan

  @override
  ConsumerState<PlanEditScreen> createState() => _PlanEditScreenState();
}

class _PlanEditScreenState extends ConsumerState<PlanEditScreen> {
  late final TextEditingController _notes;
  late List<ChecklistItem> _items;
  late List<SketchPin> _pins;
  late final String _initial; // el plan como llegó, para saber si hay cambios sin guardar
  int? _selectedPin;
  bool _busy = false;
  bool _dragLocked = false; // un dedo sobre un pin: la lista no se desplaza

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _notes = TextEditingController(text: p?.notes ?? '');
    _items = List.of(p?.items ?? const <ChecklistItem>[]);
    _pins = List.of(p?.sketch?.pins ?? const <SketchPin>[]);
    _initial = jsonEncode(_draft().toJson());
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  bool get _dirty => jsonEncode(_draft().toJson()) != _initial;

  /// El plan tal como está en pantalla.
  Plan _draft() {
    final notes = _notes.text.trim();
    return Plan(
      items: _items,
      notes: notes.isEmpty ? null : notes,
      sketch: widget.plan?.sketch?.withPins(_pins),
    );
  }

  void _addItem(ChecklistKind kind) => setState(() {
        _items = [
          ..._items,
          ChecklistItem(id: nextLocalId(_items.map((i) => i.id)), kind: kind, text: '', quantity: 1),
        ];
      });

  void _updateItem(ChecklistItem item) => setState(() {
        _items = [for (final i in _items) i.id == item.id ? item : i];
      });

  void _removeItem(int id) => setState(() => _items = [for (final i in _items) if (i.id != id) i]);

  void _updatePin(SketchPin pin) => setState(() {
        _pins = [for (final p in _pins) p.id == pin.id ? pin : p];
      });

  // Suma el desplazamiento a la posición más reciente del pin (varios eventos pueden llegar entre dos dibujos).
  void _movePin(int id, double dx, double dy) => setState(() {
        _pins = [
          for (final p in _pins)
            p.id == id ? p.copyWith(x: (p.x + dx).clamp(0.0, 1.0), y: (p.y + dy).clamp(0.0, 1.0)) : p,
        ];
      });

  void _addPin(double x, double y) => setState(() {
        final id = nextLocalId(_pins.map((p) => p.id));
        _pins = [..._pins, SketchPin(id: id, label: 'P$id', x: x, y: y)];
        _selectedPin = id;
      });

  void _removePin(int id) => setState(() {
        _pins = [for (final p in _pins) if (p.id != id) p];
        _selectedPin = null;
      });

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context); // se guardan antes del await
    final navigator = Navigator.of(context);
    final actions = ref.read(planActionsProvider);
    setState(() => _busy = true);
    try {
      await actions.save(widget.jobId, _draft());
      navigator.pop();
      messenger.toast('Plan guardado');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.toast('No se pudo guardar. Revisa tu conexión.');
    }
  }

@override
  Widget build(BuildContext context) => UnsavedGuard(
        dirty: _dirty && !_busy,
        child: _form(context),
      );

  Widget _form(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final sketch = widget.plan?.sketch;
    SketchPin? selected;
    for (final p in _pins) {
      if (p.id == _selectedPin) selected = p;
    }

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            subtitle: widget.folio,
            title: 'Editar plan',
            onBack: _busy ? null : () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              physics: _dragLocked ? const NeverScrollableScrollPhysics() : null,
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: TextField(
                    controller: _notes,
                    onChanged: (_) => setState(() {}), // actualiza si hay cambios sin guardar
                    maxLines: 4,
                    maxLength: 1000, // largo máximo de las notas
                    decoration: const InputDecoration(labelText: 'Notas para el técnico'),
                  ),
                ),
                const SizedBox(height: 12),
                _ItemsEditor(
                  title: 'Material',
                  kind: ChecklistKind.material,
                  items: [for (final i in _items) if (i.kind == ChecklistKind.material) i],
                  onAdd: () => _addItem(ChecklistKind.material),
                  onChanged: _updateItem,
                  onRemove: _removeItem,
                ),
                const SizedBox(height: 12),
                _ItemsEditor(
                  title: 'Herramienta',
                  kind: ChecklistKind.tool,
                  items: [for (final i in _items) if (i.kind == ChecklistKind.tool) i],
                  onAdd: () => _addItem(ChecklistKind.tool),
                  onChanged: _updateItem,
                  onRemove: _removeItem,
                ),
                const SizedBox(height: 12),
                if (sketch == null) // la imagen del croquis se sube desde la web
                  const Text(
                    'Este plan no tiene croquis. El croquis se sube desde la web.',
                    style: TextStyle(color: AppColors.gris600),
                  )
                else ...[
                  const Text('Croquis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Text(
                    'Toca un lugar vacío para agregar un punto. Arrastra un punto para moverlo.',
                    style: TextStyle(fontSize: 13, color: AppColors.gris600),
                  ),
                  const SizedBox(height: 8),
                  SketchEditor(
                    sketch: sketch.withPins(_pins),
                    selectedId: _selectedPin,
                    onAdd: _addPin,
                    onSelect: (id) => setState(() => _selectedPin = id),
                    onDragLock: (v) => setState(() => _dragLocked = v),
                    onMove: _movePin,
                  ),
                  const SizedBox(height: 10),
                  if (selected != null)
                    _PinForm(
                      key: ValueKey(selected.id), // un formulario nuevo por cada pin
                      pin: selected,
                      onChanged: _updatePin,
                      onRemove: () => _removePin(selected!.id),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSavePlan(_draft()) && !_busy ? _save : null, // no deja guardar renglones vacíos
                child: Text(_busy ? 'Guardando…' : 'Guardar plan'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una lista de renglones editables (material o herramienta) con su botón para agregar.
class _ItemsEditor extends StatelessWidget {
  const _ItemsEditor({
    required this.title,
    required this.kind,
    required this.items,
    required this.onAdd,
    required this.onChanged,
    required this.onRemove,
  });

  final String title;
  final ChecklistKind kind;
  final List<ChecklistItem> items;
  final VoidCallback onAdd;
  final ValueChanged<ChecklistItem> onChanged;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gris600)),
          for (final i in items) _ItemRow(key: ValueKey(i.id), item: i, onChanged: onChanged, onRemove: onRemove),
          TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Agregar')),
        ],
      ),
    );
  }
}

/// Un renglón: nombre, cantidad y botón para quitarlo. Tiene sus propios controladores.
class _ItemRow extends StatefulWidget {
  const _ItemRow({super.key, required this.item, required this.onChanged, required this.onRemove});

  final ChecklistItem item;
  final ValueChanged<ChecklistItem> onChanged;
  final ValueChanged<int> onRemove;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late final _text = TextEditingController(text: widget.item.text);
  late final _qty = TextEditingController(
      text: widget.item.quantity == null ? '' : '${widget.item.quantity}'.replaceAll(RegExp(r'\.0$'), ''));

  @override
  void dispose() {
    _text.dispose();
    _qty.dispose();
    super.dispose();
  }

  bool _touched = false; // el campo en rojo solo aparece después de que el ingeniero lo toca

  void _emit() {
    final q = num.tryParse(_qty.text.trim().replaceAll(',', '.'));
    setState(() => _touched = true);
    widget.onChanged(q == null // vacío o ".": sin cantidad, y el plan no se puede guardar
        ? widget.item.copyWith(text: _text.text, clearQuantity: true)
        : widget.item.copyWith(text: _text.text, quantity: q));
  }

  /// Borde rojo sin texto de error (el renglón es angosto).
  InputDecoration _decoration(String hint, bool invalid) => InputDecoration(
        hintText: hint,
        isDense: true,
        errorText: _touched && invalid ? '' : null,
        errorStyle: const TextStyle(height: 0, fontSize: 0),
      );

  @override
  Widget build(BuildContext context) {
    final q = num.tryParse(_qty.text.trim().replaceAll(',', '.'));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              onChanged: (_) => _emit(),
              inputFormatters: shortText(80),
              decoration: _decoration('Nombre', _text.text.trim().isEmpty),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: TextField(
              controller: _qty,
              onChanged: (_) => _emit(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: decimalInput, // solo números
              decoration: _decoration('Cant.', q == null || q <= 0),
            ),
          ),
          IconButton(
            tooltip: 'Quitar',
            onPressed: () => widget.onRemove(widget.item.id),
            icon: const Icon(Icons.delete_outline, color: AppColors.gris600),
          ),
        ],
      ),
    );
  }
}

/// La etiqueta y la nota del pin elegido, y el botón para quitarlo.
class _PinForm extends StatefulWidget {
  const _PinForm({super.key, required this.pin, required this.onChanged, required this.onRemove});

  final SketchPin pin;
  final ValueChanged<SketchPin> onChanged;
  final VoidCallback onRemove;

  @override
  State<_PinForm> createState() => _PinFormState();
}

class _PinFormState extends State<_PinForm> {
  late final _label = TextEditingController(text: widget.pin.label);
  late final _note = TextEditingController(text: widget.pin.note ?? '');

  @override
  void dispose() {
    _label.dispose();
    _note.dispose();
    super.dispose();
  }

  // Se manda la posición actual del widget (el pin puede haberse movido mientras se escribe).
  void _emit() => widget.onChanged(widget.pin.copyWith(label: _label.text, note: _note.text));

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _label,
                  onChanged: (_) => _emit(),
                  inputFormatters: shortText(8), // cabe en el círculo del pin
                  decoration: const InputDecoration(labelText: 'Etiqueta (ej. C3)'),
                ),
              ),
              IconButton(
                tooltip: 'Quitar punto',
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline, color: AppColors.gris600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            onChanged: (_) => _emit(),
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Nota del punto'),
          ),
        ],
      ),
    );
  }
}
