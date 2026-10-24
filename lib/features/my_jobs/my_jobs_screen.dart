import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget

import '../../core/theme/app_colors.dart'; // colores
import '../../core/time/time_utils.dart'; // formatClock
import '../../core/widgets/app_card.dart'; // la tarjeta compartida
import '../../core/widgets/app_header.dart'; // encabezado navy
import '../../core/widgets/tag_chip.dart'; // etiquetas
import '../../domain/models/my_job_models.dart'; // MyJob
import '../../providers/my_jobs_providers.dart'; // myJobsProvider
import '../my_day/visit_tags.dart'; // jobTypeChip

/// Mis trabajos: lo que el técnico terminó y qué decidió el ingeniero. Solo lectura.
class MyJobsScreen extends ConsumerWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(myJobsProvider);
    return Column(
      children: [
        const AppHeader(title: 'Mis trabajos', subtitle: 'Lo que ya terminaste'),
        Expanded(
          child: jobs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudo cargar. Revisa tu conexión.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
                    onPressed: () => ref.invalidate(myJobsProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            data: (list) => list.isEmpty
                ? const Center(
                    child: Text('Todavía no has terminado trabajos.',
                        style: TextStyle(color: AppColors.gris600)),
                  )
                : RefreshIndicator( // jalar hacia abajo para actualizar
                    onRefresh: () async {
                      ref.invalidate(myJobsProvider);
                      await ref.read(myJobsProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _MyJobCard(job: list[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Etiqueta del estado de revisión.
Widget _statusChip(MyJobStatus s) {
  switch (s) {
    case MyJobStatus.toValidate:
      return const TagChip(
          label: 'Por validar', background: AppColors.infoSuave, foreground: AppColors.info);
    case MyJobStatus.validated:
      return const TagChip(
          label: 'Validado', background: AppColors.okSuave, foreground: AppColors.ok);
    case MyJobStatus.returned:
      return const TagChip(
          label: 'Regresado', background: AppColors.rojoSuave, foreground: AppColors.rojoOscuro);
  }
}

/// Tarjeta de un trabajo. Si fue regresado, la nota del ingeniero va destacada.
class _MyJobCard extends StatelessWidget {
  const _MyJobCard({required this.job});

  final MyJob job;

  @override
  Widget build(BuildContext context) {
    final note = job.engineerNote;
    final engineer = job.engineerName;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(job.clientName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Text(job.folio, style: const TextStyle(fontSize: 12, color: AppColors.gris600)),
            ],
          ),
          Text(job.placeName, style: const TextStyle(fontSize: 13, color: AppColors.gris600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [_statusChip(job.status), jobTypeChip(job.type)],
          ),
          const SizedBox(height: 8),
          Text(
            'Cerraste a las ${formatClock(job.closedAt)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gris600),
          ),
          if (job.status == MyJobStatus.returned && note != null) ...[
            const SizedBox(height: 10),
            Container( // la nota del ingeniero, bien visible
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.rojoSuave,
                borderRadius: BorderRadius.circular(10),
                border: const Border(left: BorderSide(color: AppColors.rojo, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    engineer == null ? 'Nota del ingeniero' : 'Nota de $engineer',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.rojoOscuro),
                  ),
                  const SizedBox(height: 4),
                  Text(note, style: const TextStyle(fontSize: 14, color: AppColors.gris900)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
