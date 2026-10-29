import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/events/event_data.dart';
import '../../../domain/format.dart';

/// Cómo se cerró la visita y los datos que el técnico escribió al cerrarla. Solo lectura.
class ClosingCard extends StatelessWidget {
  const ClosingCard({super.key, required this.closing});

  final EventData? closing; // null si la acción de cierre ya no está guardada en este teléfono

  /// Pares título → texto de lo que se guardó al cerrar.
  List<(String, String)> _lines() => switch (closing) {
        FinishedEvent(:final confirmedBy, :final confirmedRole) => [
            if (confirmedBy != null)
              ('Extras confirmados por', confirmedRole == null || confirmedRole.isEmpty ? confirmedBy : '$confirmedBy ($confirmedRole)'),
          ],
        ContinueTomorrowEvent e => [
            for (final m in e.materials) ('Usado: ${m.text}', '${formatNumber(m.used)} de ${formatNumber(m.planned)}'),
            if (e.leftOnSite.isNotEmpty) ('Se queda en el sitio', e.leftOnSite),
            if (e.missing.isNotEmpty) ('Falta por hacer', e.missing),
            if (e.laidCable) ('Cableado', 'Se tendió cable hoy'),
          ],
        BlockedEvent e => [
            ('Motivo', e.reason.label),
            if (e.incidentKind != null) ('Tipo de incidente', e.incidentKind!.label),
            if (e.note.isNotEmpty) ('Nota', e.note),
          ],
        NoAnswerConfirmedEvent() => [('Resultado', 'Nadie atendió; se cerró la visita.')],
        _ => [],
      };

  @override
  Widget build(BuildContext context) {
    final lines = _lines();
    if (closing == null) {
      return const Text(
        'Los datos del cierre no están guardados en este teléfono.',
        style: TextStyle(color: AppColors.gris600),
      );
    }
    if (lines.isEmpty) return const SizedBox.shrink(); // se terminó sin nada más que contar
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (title, text) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gris600)),
                  Text(text),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
