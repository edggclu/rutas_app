import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/time_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../domain/models/closing_models.dart';
import '../../domain/models/media_item.dart';
import '../../providers/route_providers.dart';
import '../media/media_strip.dart';
import '../my_day/visit_tags.dart';
import 'widgets/closing_card.dart';
import 'widgets/notes_section.dart';

/// Resumen de una visita ya cerrada: todo lo que se hizo y agregó. Solo lectura; lo único que
/// se puede hacer es agregar una nota por si se olvidó algo.
class VisitSummaryScreen extends ConsumerWidget {
  const VisitSummaryScreen({super.key, required this.visitId});

  final int visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(visitByIdProvider(visitId));
    if (visit == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final summary = ref.watch(visitSummaryProvider(visitId));
    final media = ref.watch(mediaForVisitProvider(visitId)).value ?? const <MediaItem>[];
    final arrived = visit.arrivedAt;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            subtitle: visit.job.folio,
            title: visit.client.name,
            onBack: () => Navigator.of(context).pop(),
            bottom: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 6, children: [...visitTags(visit.job), visitStatusChip(visit)]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (arrived != null)
                  Text('Llegaste a las ${formatClock(arrived)}', style: const TextStyle(color: AppColors.gris600)),
                const SizedBox(height: 12),
                _Section('Cierre', child: ClosingCard(closing: summary.closing)),
                if (summary.warranty != null)
                  _Section('Garantía', child: _WarrantyLine(summary.warranty!.cause, summary.warranty!.serial)),
                if (summary.extras.isNotEmpty)
                  _Section('Extras', child: _Lines([for (final e in summary.extras) e.notInstalled ? '${e.label} (no se instaló)' : e.label])),
                if (summary.requests.isNotEmpty)
                  _Section('Solicitudes para después', child: _Lines([for (final r in summary.requests) r.description])),
                if (media.isNotEmpty)
                  _Section('Fotos y videos', child: MediaStrip(items: media, deletable: false)), // ya no se borran
                _Section('Notas', child: NotesSection(visitId: visitId, notes: summary.notes)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un bloque con su título.
class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class _Lines extends StatelessWidget {
  const _Lines(this.lines);

  final List<String> lines;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final l in lines) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(l))],
        ),
      );
}

class _WarrantyLine extends StatelessWidget {
  const _WarrantyLine(this.cause, this.serial);

  final WarrantyCause? cause;
  final String? serial;

  @override
  Widget build(BuildContext context) => _Lines([
        if (cause != null) 'Causa: ${cause!.label}',
        if (serial != null && serial!.isNotEmpty) 'Serial: $serial',
      ]);
}
