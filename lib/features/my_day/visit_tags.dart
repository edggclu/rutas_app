import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/tag_chip.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../../domain/visit_labels.dart';

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

/// El estado de la visita con su color. Una visita cerrada sin terminar no se ve como "Hecha".
Widget visitStatusChip(Visit v) => statusTag(v.status, v.result, v.dayNumber);

/// El estado con su color, a partir de los tres datos (también lo usa la pantalla del jefe).
Widget statusTag(VisitStatus status, VisitResult? result, int? dayNumber) {
  final label = statusText(status, result, dayNumber);
  switch (status) {
    case VisitStatus.pending:
      return TagChip(label: label, background: AppColors.gris100, foreground: AppColors.gris600);
    case VisitStatus.enRoute:
      return TagChip(label: label, background: AppColors.infoSuave, foreground: AppColors.info);
    case VisitStatus.onSite:
      return TagChip(label: label, background: AppColors.okSuave, foreground: AppColors.ok);
    case VisitStatus.done:
      switch (result) {
        case VisitResult.continueLater:
        case VisitResult.noAnswer:
          return TagChip(label: label, background: AppColors.alertaSuave, foreground: AppColors.alerta);
        case VisitResult.blocked:
          return TagChip(label: label, background: AppColors.rojoSuave, foreground: AppColors.rojoOscuro);
        case VisitResult.finished:
        case null:
          return TagChip(label: label, background: AppColors.gris200, foreground: AppColors.gris900);
      }
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
