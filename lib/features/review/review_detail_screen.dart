import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerStatefulWidget
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/features/review/verdict_screen.dart';
import 'package:telyser_app/providers/review_providers.dart';

import '../../core/theme/app_colors.dart'; // colores
import '../../core/time/time_utils.dart'; // formatClock
import '../../core/widgets/app_card.dart'; // la tarjeta compartida
import '../../core/widgets/app_header.dart'; // encabezado navy
import '../../core/widgets/tag_chip.dart'; // etiquetas
import '../../core/widgets/toast.dart'; // avisos cortos
import '../../domain/format.dart'; // formatNumber
import '../../domain/models/review_models.dart'; // ReviewJob
import '../../domain/review_rules.dart'; // canValidate
import '../my_day/visit_tags.dart'; // jobTypeChip
import 'return_sheet.dart'; // la nota al regresar
import 'widgets/photo_strip.dart'; // las fotos

/// F2 · Detalle de validación: todo lo que el técnico dejó, y las dos salidas.
class ReviewDetailScreen extends ConsumerStatefulWidget {
  const ReviewDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  ConsumerState<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends ConsumerState<ReviewDetailScreen> {
  bool _busy = false; // true mientras se envía (evita doble toque)

  /// Da el trabajo por bueno y regresa a la lista.
  Future<void> _validate(ReviewJob job) async {
    final messenger = ScaffoldMessenger.of(context); // se guardan antes del await
    final navigator = Navigator.of(context);
    final actions = ref.read(reviewActionsProvider);
    setState(() => _busy = true);
    try {
      await actions.validate(job);
      navigator.pop();
      messenger.toast('Validaste ${job.folio}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.toast('No se pudo validar. Revisa tu conexión.');
    }
  }

  /// Pide la nota y regresa el trabajo al técnico.
  Future<void> _return(ReviewJob job) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final actions = ref.read(reviewActionsProvider);
    final note = await showReturnSheet(context);
    if (note == null || !mounted) return; // canceló
    setState(() => _busy = true);
    try {
      await actions.returnJob(job, note);
      navigator.pop();
      messenger.toast('Regresaste ${job.folio} con nota');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.toast('No se pudo regresar. Revisa tu conexión.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(reviewJobProvider(widget.jobId));
    if (job == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator())); // cargando, o ya se resolvió
    }
    final bottom = MediaQuery.of(context).padding.bottom;
    final plan = job.plan;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            subtitle: job.folio,
            title: job.clientName,
            onBack: () => Navigator.of(context).pop(),
            bottom: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                jobTypeChip(job.type),
                if (job.coverage == Coverage.warranty)
                  const TagChip(label: 'Garantía', background: AppColors.alertaSuave, foreground: AppColors.alerta),
                if (job.coverage == Coverage.policy)
                  const TagChip(label: 'Póliza', background: AppColors.gris100, foreground: AppColors.gris600),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard( // quién, dónde y cuándo
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('Lugar', job.placeName),
                      _InfoRow('Técnico', job.technicianName),
                      _InfoRow('Cerró', formatClock(job.closedAt)),
                    ],
                  ),
                ),
                if (job.notes != null) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Notas del técnico'),
                        const SizedBox(height: 4),
                        Text(job.notes!),
                      ],
                    ),
                  ),
                ],
                if (job.warranty != null) ...[ // solo en garantías
                  const SizedBox(height: 12),
                  _WarrantyCard(
                    job: job,
                    onVerdict: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => VerdictScreen(jobId: job.id)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _SectionTitle('Fotos (${job.photos.length})'),
                const SizedBox(height: 8),
                PhotoStrip(photos: job.photos),
                if (job.extras.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionTitle('Extras (${job.extras.length})'),
                  const SizedBox(height: 4),
                  for (final x in job.extras)
                    _ListRow(
                      text: '${formatNumber(x.quantity)} × ${x.name}',
                      tag: x.notInstalled ? 'No se instaló' : null,
                    ),
                ],
                if (plan != null && plan.items.isNotEmpty) ...[ // el plan, para comparar contra lo hecho
                  const SizedBox(height: 16),
                  const _SectionTitle('Plan del ingeniero'),
                  const SizedBox(height: 4),
                  for (final i in plan.items) _ListRow(text: i.text, trailing: i.quantityLabel),
                ],
              ],
            ),
          ),
          Container( // barra de abajo: validar o regresar
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!canValidate(job)) // garantía sin dictaminar
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Dictamina la causa de la garantía para poder validar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.alerta, fontSize: 12),
                    ),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.ok),
                  onPressed: canValidate(job) && !_busy ? () => _validate(job) : null,
                  child: const Text('Validar'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _return(job),
                  child: const Text('Regresar con nota'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La garantía: lo que dijo el técnico, el serial y el estado del dictamen.
class _WarrantyCard extends StatelessWidget {
  const _WarrantyCard({required this.job, required this.onVerdict});

  final ReviewJob job;
  final VoidCallback onVerdict;

  @override
  Widget build(BuildContext context) {
    final w = job.warranty!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Garantía'),
          const SizedBox(height: 4),
          _InfoRow('Causa del técnico', w.cause?.label ?? 'Sin causa'),
          _InfoRow('Número de serie', w.serial ?? 'Solo en foto'),
          if (w.verdict != null)
            _InfoRow('Dictamen', w.verdict!.label) // ya dictaminada
          else if (w.needsVerdict) ...[
            const SizedBox(height: 8),
            FilledButton(onPressed: onVerdict, child: const Text('Dictaminar causa')),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gris600),
      );
}

/// Un dato con su nombre: "Técnico  Luis".
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.gris600, fontSize: 13))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );
}

/// Un renglón de lista: texto, y a la derecha una cantidad o una etiqueta.
class _ListRow extends StatelessWidget {
  const _ListRow({required this.text, this.trailing, this.tag});

  final String text;
  final String? trailing; // cantidad en gris
  final String? tag; // etiqueta en ámbar

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(text)),
            if (trailing != null)
              Text(trailing!, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.gris600)),
            if (tag != null)
              Text(tag!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.alerta)),
          ],
        ),
      );
}