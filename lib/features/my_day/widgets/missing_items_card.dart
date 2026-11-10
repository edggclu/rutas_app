import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/event_models.dart';
import '../../../providers/route_providers.dart';
import '../../shared/run_undoable.dart';

/// Lo que el técnico marcó como faltante al salir y todavía no consigue. Cuando lo consigue, toca
/// "Ya lo tengo" (o "Ya tengo todo") y la lista se actualiza. No bloquea nada: puede trabajar sin
/// esos renglones. Si no falta nada, no dibuja nada.
class MissingItemsCard extends ConsumerWidget {
  const MissingItemsCard(
      {super.key, required this.visitId, this.topSpacing = 0});

  final int visitId;
  final double
      topSpacing; // espacio arriba, solo cuando la tarjeta se ve (así no deja huecos)

  Future<void> _obtained(
          BuildContext context, WidgetRef ref, List<MissingItem> items) =>
      runUndoable(
        context,
        ref,
        action: (a) => a.departure.markObtained(visitId: visitId, items: items),
        message: items.length == 1
            ? 'Marcaste que ya tienes ${items.single.text}'
            : 'Marcaste que ya tienes todo',
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(missingItemsProvider(visitId));
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
        decoration: BoxDecoration(
            color: AppColors.alertaSuave,
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Te falta para esta visita',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.alerta)),
            const SizedBox(height: 2),
            const Text('Puedes trabajar sin esto. Cuando lo consigas, márcalo.',
                style: TextStyle(fontSize: 12, color: AppColors.gris900)),
            const SizedBox(height: 6),
            for (final i in items)
              Row(
                children: [
                  Icon(
                      i.kind == ChecklistKind.tool
                          ? Icons.build_outlined
                          : Icons.inventory_2_outlined,
                      size: 18,
                      color: AppColors.alerta),
                  const SizedBox(width: 8),
                  Expanded(child: Text(i.text)),
                  TextButton(
                      onPressed: () => _obtained(context, ref, [i]),
                      child: const Text('Ya lo tengo')),
                ],
              ),
            if (items.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => _obtained(context, ref, items),
                    child: const Text('Ya tengo todo')),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Te faltan N" para la tarjeta de la visita en Mi día. Si no falta nada, no dibuja nada.
class MissingCountTag extends ConsumerWidget {
  const MissingCountTag({super.key, required this.visitId});

  final int visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(missingItemsProvider(visitId)).length;
    if (n == 0) return const SizedBox.shrink();
    return TagChip(
      label: n == 1 ? 'Te falta 1' : 'Te faltan $n',
      background: AppColors.alertaSuave,
      foreground: AppColors.alerta,
    );
  }
}
