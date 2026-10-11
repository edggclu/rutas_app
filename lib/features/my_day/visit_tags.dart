import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/tag_chip.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';

Widget jobTypeChip(JobType t) {
  switch (t) {
    case JobType.installation:
      return const TagChip(
          label: 'Instalación', background: AppColors.infoSuave, foreground: AppColors.info);
    case JobType.corrective:
      return const TagChip(
          label: 'Correctivo', background: AppColors.alertaSuave, foreground: AppColors.alerta);
    case JobType.preventive:
      return const TagChip(
          label: 'Preventivo', background: AppColors.okSuave, foreground: AppColors.ok);
  }
}

Widget statusChip(VisitStatus s) {
  switch (s) {
    case VisitStatus.pending:
      return const TagChip(
          label: 'Por hacer', background: AppColors.gris100, foreground: AppColors.gris600);
    case VisitStatus.enRoute:
      return const TagChip(
          label: 'En camino', background: AppColors.infoSuave, foreground: AppColors.info);
    case VisitStatus.onSite:
      return const TagChip(
          label: 'En sitio', background: AppColors.okSuave, foreground: AppColors.ok);
    case VisitStatus.done:
      return const TagChip(
          label: 'Hecha', background: AppColors.gris200, foreground: AppColors.gris900);
  }
}

/// Etiquetas de una visita: tipo, Urgente y cobertura (garantía o póliza).
List<Widget> visitTags(Job job) => [
      jobTypeChip(job.type),
      if (job.priority == Priority.urgent)
        const TagChip(
            label: 'URGENTE', background: AppColors.rojo, foreground: Colors.white),
      if (job.coverage == Coverage.warranty)
        const TagChip(
            label: 'Garantía', background: AppColors.alertaSuave, foreground: AppColors.alerta),
      if (job.coverage == Coverage.policy)
        const TagChip(
            label: 'Póliza', background: AppColors.gris100, foreground: AppColors.gris600),
    ];
