import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/features/my_day/arrival_panel.dart';
import 'package:telyser_app/features/no_answer/no_answer.dart';
import 'package:telyser_app/features/shared/run_undoable.dart';
import 'package:telyser_app/features/site/site_screen.dart';
import 'package:telyser_app/providers/actions.provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/alert_box.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/slide_to_confirm.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import 'visit_tags.dart';

/// C3 · Tarjeta de visita: todo lo necesario para llegar y saber qué hacer.
/// Abajo muestra el deslizable "Llegué" o, si ya llegó, el panel "¿Ya te abrieron?".
class VisitDetailScreen extends ConsumerWidget {
  const VisitDetailScreen({super.key, required this.visit});

  final Visit visit;

  Future<void> _openMaps(BuildContext context) async {
    final p = visit.place;
    final label = Uri.encodeComponent(p.name);
    final uris = <Uri>[
      if (p.lat != null && p.lng != null)
        // geo: abre el selector de Android (Maps, Waze…).
        Uri.parse('geo:${p.lat},${p.lng}?q=${p.lat},${p.lng}($label)'),
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query='
        '${p.lat != null && p.lng != null ? '${p.lat},${p.lng}' : Uri.encodeComponent(p.address)}',
      ),
    ];
    for (final u in uris) {
      try {
        if (await launchUrl(u, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
    if (context.mounted) _toast(context, 'No se pudo abrir el mapa.');
  }

  // TODO(paso 2): cada toque de llamar / WhatsApp se registra en la bitácora.
  Future<void> _call(BuildContext context, String phone) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && context.mounted) _toast(context, 'No se pudo llamar.');
  }

  Future<void> _whatsapp(BuildContext context, String phone) async {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) digits = '52$digits';
    final ok = await launchUrl(
      Uri.parse('https://wa.me/$digits'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) _toast(context, 'No se pudo abrir WhatsApp.');
  }
  
    Future<void> _arrive(BuildContext context, WidgetRef ref) async { // se ejecuta al deslizar "Llegué"
    await runUndoable( // guarda y muestra la barra
      context, ref, // dónde mostrar los avisos
      action: (a) => a.arrival.arrive(visitId: visit.id), // el área de llegada: lee el GPS y guarda
      message: 'Marcaste Llegué', // texto de la barra
      errorMessage: 'No se pudo guardar tu llegada. Intenta de nuevo.', // texto del error
    );
  }

    /// se ejecuta al tocar "No me abren" en el panel
    Future<void> _noAnswer(BuildContext context, WidgetRef ref) async { 
    final navigator = Navigator.of(context); 
    final messenger = ScaffoldMessenger.of(context); 
    try { 
      await ref.read(visitActionsProvider).noAnswer.reportNoAnswer(visitId: visit.id); // avisa a la oficina (una sola vez)
      navigator.push( 
        MaterialPageRoute<void>( 
          builder: (_) => NoAnswerScreen(visitId: visit.id), 
        ),
      );
    } catch (_) {
      messenger.showSnackBar(const SnackBar( 
        content: Text('No se pudo guardar. Intenta de nuevo.'), 
      ));
    }
  }

  void _toast(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = visit.job;
    final place = visit.place;
    final contact = place.contact;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            subtitle: job.folio,
            title: place.name,
            onBack: () => Navigator.of(context).pop(),
            bottom: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [...visitTags(job), statusChip(visit.status)],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Box(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.address,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy900,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () => _openMaps(context),
                        child: const Text('Abrir en Maps / Waze'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (contact != null)
                  _Box(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              if (contact.role != null)
                                Text(
                                  contact.role!,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.gris600),
                                ),
                              Text(
                                contact.phone,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.gris600),
                              ),
                            ],
                          ),
                        ),
                        _SmallButton(
                          label: 'Llamar',
                          color: AppColors.navy900,
                          onTap: () => _call(context, contact.phone),
                        ),
                        const SizedBox(width: 8),
                        _SmallButton(
                          label: 'WhatsApp',
                          color: AppColors.ok,
                          onTap: () => _whatsapp(context, contact.phone),
                        ),
                      ],
                    ),
                  ),
                if (place.accessNotes != null) ...[
                  const SizedBox(height: 10),
                  AlertBox(title: 'Notas de acceso', body: place.accessNotes!),
                ],
                const SizedBox(height: 10),
                _Box(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Qué hay que hacer',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gris600),
                      ),
                      const SizedBox(height: 4),
                      Text(job.description),
                      if (job.planSummary != null) ...[
                        const SizedBox(height: 4),
                        Text(job.planSummary!),
                        const SizedBox(height: 6),
                        GestureDetector(
                          // TODO(paso 5): pantalla D1 "Ver plan completo".
                          onTap: () => _toast(context, 'El plan completo llega con el paso 5.'),
                          child: const Text(
                            'Ver plan completo ›',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.rojo),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (visit.client.overdue) ...[
                  const SizedBox(height: 10),
                  const AlertBox(
                    title: 'Saldo vencido',
                    body: 'Este cliente tiene saldo vencido. '
                        'No agregues equipo sin autorización.',
                    background: AppColors.alertaSuave,
                    foreground: AppColors.alerta,
                  ),
                ],
                if (job.coverage == Coverage.warranty && job.warrantyGuide != null) ...[
                  const SizedBox(height: 10),
                  AlertBox(
                    title: 'Guía de garantía',
                    body: job.warrantyGuide!,
                    background: AppColors.alertaSuave,
                    foreground: AppColors.alerta,
                  ),
                ],
              ],
            ),
          ),
          if(visit.status == VisitStatus.onSite)
            // si ya llego muestra: "Ya te abrieron?"
            ArrivalPanel(
              visit: visit, 
              // al tocar "Empezar"
              onStart: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => SiteScreen(visitId: visit.id),
                )
              ), 
              // al tocar 'no me abren'
              onNoAnswer: () => _noAnswer(context, ref)
            )
            
          // si no ha llegado y la visita no está terminada
          else if (visit.status != VisitStatus.done)
            Container (
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 12, 16,
                        12 + MediaQuery.of(context).padding.bottom),
              child: SlideToConfirm(
                label: 'Desliza: LLegue', 
                onConfirmed: () => _arrive(context,ref)),
            )
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gris200),
        ),
        child: child,
      );
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
}
