import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/features/shared/run_undoable.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/time_utils.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/slide_to_confirm.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';

/// C2 · Salida (inicio del día).
///
/// El técnico revisa la lista de material y herramienta de cada visita:
///  - Si lleva todo, desliza "Llevo todo".
///  - Si le falta algo, toca ese renglón (queda en ámbar como "Me falta") y
///    desliza "Salgo". Se avisa a Axel y al jefe ANTES de que salga.
///
/// Al confirmar: se encolan los eventos, la pantalla se cierra y aparece la
/// barra de deshacer. El estado de las visitas cambia solo, porque
/// `myDayProvider` vuelve a calcularse con lo que hay en la cola.
class DepartureScreen extends ConsumerStatefulWidget {
  const DepartureScreen({super.key, required this.route});
  final DayRoute route;

  @override
  ConsumerState<DepartureScreen> createState() => _DepartureScreenState();
}

class _DepartureScreenState extends ConsumerState<DepartureScreen> {
  /// Renglones marcados como faltantes: (id de visita, id de renglón).
  final Set<(int, int)> _missing = {};
  final _slideKey = GlobalKey<SlideToConfirmState>();
  bool _saving = false;

  List<Visit> get _pending =>
      widget.route.visits.where((v) => v.status != VisitStatus.done).toList();

  void _toggle((int, int) key) => setState(() {
        if (!_missing.add(key)) _missing.remove(key);
      });

  Map<int, List<ChecklistItem>> _missingByVisit() {
    final out = <int, List<ChecklistItem>>{};
    for (final v in _pending) {
      for (final i in v.checklist.items) {
        if (_missing.contains((v.id, i.id))) {
          (out[v.id] ??= []).add(i);
        }
      }
    }
    return out;
  }

    Future<void> _confirm() async { // se ejecuta al completar el deslizamiento
    setState(() => _saving = true); // bloquea el deslizable mientras guarda
    final missingCount = _missing.length; // cuántos renglones le faltan (para el texto)
    await runUndoable( // guarda, cierra y muestra la barra
      context, ref, // dónde mostrar los avisos
      action: (a) => a.departure.confirmDeparture( // el área de salida
        visits: _pending, // las visitas por hacer
        missing: _missingByVisit(), // los renglones faltantes por visita
      ),
      message: missingCount == 0 // texto de la barra
          ? 'Confirmaste la salida' // sin faltantes
          : 'Confirmaste la salida (te faltan $missingCount)', // con faltantes
      after: AfterSave.pop, // cierra la pantalla de Salida
      errorMessage: 'No se pudo guardar la salida. Intenta de nuevo.', // texto del error
      onError: () { // si falla
        if (!mounted) return; // si ya cerró la pantalla, no hace nada
        setState(() => _saving = false); // desbloquea
        _slideKey.currentState?.reset(); // regresa el deslizable
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            subtitle: formatLongDate(widget.route.date),
            title: 'Salida',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Revisa que llevas todo. Si te falta algo, toca el renglón: '
                  'se avisa a Axel y al jefe antes de que salgas.',
                  style: TextStyle(color: AppColors.gris600),
                ),
                const SizedBox(height: 12),
                for (final v in _pending) ...[
                  _VisitSection(
                    visit: v,
                    missing: _missing,
                    onToggle: _toggle,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            child: SlideToConfirm(
              key: _slideKey,
              enabled: !_saving,
              label: _missing.isEmpty
                  ? 'Desliza: Llevo todo'
                  : 'Desliza: Salgo (me faltan ${_missing.length})',
              onConfirmed: _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una visita con su lista: Material y Herramienta por separado.
class _VisitSection extends StatelessWidget {
  const _VisitSection({
    required this.visit,
    required this.missing,
    required this.onToggle,
  });

  final Visit visit;
  final Set<(int, int)> missing;
  final void Function((int, int)) onToggle;

  String get _sourceLabel {
    switch (visit.checklist.source) {
      case ChecklistSource.plan:
        return 'Del plan del ingeniero';
      case ChecklistSource.quote:
        return 'De la cotización';
      case ChecklistSource.none:
        return 'Sin lista. Lleva tu material de siempre.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = visit.checklist;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gris200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${visit.order} · ${visit.place.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            _sourceLabel,
            style: const TextStyle(fontSize: 12, color: AppColors.gris600),
          ),
          if (c.materials.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _GroupTitle('Material'),
            for (final i in c.materials) _row(i),
          ],
          if (c.tools.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _GroupTitle('Herramienta'),
            for (final i in c.tools) _row(i),
          ],
        ],
      ),
    );
  }

  Widget _row(ChecklistItem i) {
    final key = (visit.id, i.id);
    return _ItemRow(
      item: i,
      isMissing: missing.contains(key),
      onTap: () => onToggle(key),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.gris600,
          ),
        ),
      );
}

/// Renglón tocable: verde = lo llevo, ámbar = me falta.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.isMissing,
    required this.onTap,
  });

  final ChecklistItem item;
  final bool isMissing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isMissing ? AppColors.alertaSuave : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              Icon(
                isMissing ? Icons.error : Icons.check_circle,
                size: 20,
                color: isMissing ? AppColors.alerta : AppColors.ok,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item.text)),
              if (isMissing)
                const Text(
                  'Me falta',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.alerta,
                  ),
                )
              else
                Text(
                  item.quantityLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gris600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}