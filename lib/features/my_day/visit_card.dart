import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/time_utils.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import 'visit_tags.dart';

/// Tarjeta de visita de la lista "Mi día".
class VisitCard extends StatelessWidget {
  const VisitCard({super.key, required this.visit, required this.number, required this.onTap});

  final Visit visit;
  final int number; // su lugar en la ruta de hoy (la ruta se ordena en la app, no viene del servidor)
  final VoidCallback onTap;

  /// Folio, "Día N" (solo instalaciones, sin total) y hora de cita si existe.
  String get _line {
    final parts = <String>[visit.job.folio];
    if (visit.job.type == JobType.installation && visit.dayNumber != null) {
      parts.add('Día ${visit.dayNumber}');
    }
    if (visit.scheduledAt != null) {
      parts.add('Cita ${formatClock(visit.scheduledAt!)}');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final done = visit.status == VisitStatus.done;
    return Opacity(
      opacity: done ? 0.6 : 1,
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gris200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.navy900,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.place.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gris900,
                            ),
                          ),
                          Text(
                            visit.place.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gris600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [...visitTags(visit.job), visitStatusChip(visit)],
                ),
                const SizedBox(height: 8),
                Text(
                  _line,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gris600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
