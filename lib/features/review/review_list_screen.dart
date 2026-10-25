import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/providers/review_providers.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/time_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/tag_chip.dart';
import '../../domain/models/review_models.dart';
import '../my_day/visit_tags.dart';
import 'review_detail_screen.dart';

/// F1 · Por validar: trabajos terminados que el ingeniero debe revisar.
class ReviewListScreen extends ConsumerWidget {
  const ReviewListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(reviewListProvider);
    return Column(
      children: [
        const AppHeader(title: 'Por validar', subtitle: 'Trabajos terminados por revisar'),
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
                    onPressed: () => ref.invalidate(reviewListProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            data: (list) => list.isEmpty
                ? const Center(
                    child: Text('No hay trabajos por validar.', style: TextStyle(color: AppColors.gris600)),
                  )
                : RefreshIndicator( // jalar hacia abajo para actualizar
                    onRefresh: () async {
                      ref.invalidate(reviewListProvider);
                      await ref.read(reviewListProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _ReviewCard(job: list[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de un trabajo: quién, qué, cuándo cerró y cuánto trae.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.job});

  final ReviewJob job;

  String _count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ReviewDetailScreen(jobId: job.id)),
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(job.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text(job.folio, style: const TextStyle(fontSize: 12, color: AppColors.gris600)),
              ],
            ),
            Text(job.placeName, style: const TextStyle(fontSize: 13, color: AppColors.gris600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                jobTypeChip(job.type),
                if (job.needsVerdict) // la garantía pide dictamen del ingeniero
                  const TagChip(
                    label: 'Garantía sin causa',
                    background: AppColors.alertaSuave,
                    foreground: AppColors.alerta,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${job.technicianName} · cerró ${formatClock(job.closedAt)} · '
              '${_count(job.photos.length, 'foto', 'fotos')} · ${_count(job.extras.length, 'extra', 'extras')}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gris600),
            ),
          ],
        ),
      ),
    );
  }
}