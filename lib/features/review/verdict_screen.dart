import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/core/widgets/unsaved_guard.dart';
import 'package:telyser_app/providers/review_providers.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/choice_group.dart';
import '../../core/widgets/toast.dart';
import '../../domain/models/closing_models.dart';
import 'widgets/photo_strip.dart';

/// F3 · Dictamen de causa: el ingeniero revisa las fotos y fija la causa.
class VerdictScreen extends ConsumerStatefulWidget {
  const VerdictScreen({super.key, required this.jobId});

  final int jobId;

  @override
  ConsumerState<VerdictScreen> createState() => _VerdictScreenState();
}

class _VerdictScreenState extends ConsumerState<VerdictScreen> {
  WarrantyCause? _cause; // causa elegida (null = aún no elige)
  bool _saving = false;

  Future<void> _save() async {
    final job = ref.read(reviewJobProvider(widget.jobId));
    if (job == null || _cause == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final actions = ref.read(reviewActionsProvider);
    setState(() => _saving = true);
    try {
      await actions.submitVerdict(job, _cause!);
      navigator.pop();
      messenger.toast('Dictamen guardado');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.toast('No se pudo guardar. Revisa tu conexión.');
    }
  }

@override
  Widget build(BuildContext context) => UnsavedGuard(
        dirty: _cause != null && !_saving,
        child: _form(context),
      );

  Widget _form(BuildContext context) {
    final job = ref.watch(reviewJobProvider(widget.jobId));
    if (job == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final bottom = MediaQuery.of(context).padding.bottom;
    final w = job.warranty;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            subtitle: job.folio,
            title: 'Dictamen de causa',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Fotos de la falla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                PhotoStrip(photos: job.failurePhotos),
                const SizedBox(height: 12),
                Text('Número de serie: ${w?.serial ?? 'solo en foto'}'),
                Text(
                  'Causa del técnico: ${w?.cause?.label ?? 'sin causa'}',
                  style: const TextStyle(color: AppColors.gris600),
                ),
                const SizedBox(height: 16),
                ChoiceGroup<WarrantyCause>(
                  title: 'Causa del dictamen',
                  options: [for (final c in WarrantyCause.values) (c, c.label)],
                  selected: _cause,
                  onSelected: (v) => setState(() => _cause = v),
                ),
                const Text(
                  'Si con las fotos no se puede saber, elige “No se sabe”: queda confirmado.',
                  style: TextStyle(fontSize: 12, color: AppColors.gris600),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            child: FilledButton(
              onPressed: _cause != null && !_saving ? _save : null,
              child: const Text('Confirmar dictamen'),
            ),
          ),
        ],
      ),
    );
  }
}