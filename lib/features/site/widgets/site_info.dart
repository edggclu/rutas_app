import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/rules/visit_state.dart';
import 'package:telyser_app/providers/route_providers.dart';

import '../../../core/theme/app_colors.dart'; // colores
import '../../../core/time/time_utils.dart'; // formatClock
import '../../../core/widgets/alert_box.dart'; // caja de aviso
import '../../../domain/events/event_data.dart'; // NoAnswerReportedEvent
import '../../no_answer/no_answer_screen.dart'; // pantalla "No me abren"

/// Aviso de que se reportó "No me abren", con un enlace para volver a la espera.
/// No ocupa lugar si nunca se reportó.
class NoAnswerBanner extends ConsumerWidget { // widget que puede leer providers
  const NoAnswerBanner({super.key, required this.visitId}); // recibe solo el id

  final int visitId; // id de la visita

  @override
  Widget build(BuildContext context, WidgetRef ref) { // dibuja el aviso
    final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[]; // las acciones de la cola
    final reported = events.any( // ¿alguna vez avisó que nadie abría?
        (e) => e.visitId == visitId && e.data is NoAnswerReportedEvent); // un evento de esa clase para esta visita
    if (!reported) return const SizedBox.shrink(); // si no, no se dibuja nada
    return Column( // aviso y enlace
      crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
      children: [
        const AlertBox( // caja de aviso ámbar
          title: 'Aviso a la oficina', // título
          body: 'Reportaste que nadie abría.', // texto
          background: AppColors.alertaSuave, // fondo ámbar claro
          foreground: AppColors.alerta, // texto ámbar
        ),
        TextButton( // enlace para volver a la espera
          onPressed: () => Navigator.of(context).push( // abre C4
            MaterialPageRoute<void>( // pantalla nueva
              builder: (_) => NoAnswerScreen(visitId: visitId), // la pantalla de espera
            ),
          ),
          child: const Text('Ver espera ›'), // texto del enlace
        ),
        const SizedBox(height: 4), // espacio vertical
      ],
    );
  }
}

/// Hora de llegada y acompañantes.
class ArrivalInfo extends StatelessWidget { // widget sin estado propio
  const ArrivalInfo({super.key, required this.visit}); // recibe la visita

  final Visit visit; // la visita

  @override
  Widget build(BuildContext context) { // dibuja la información
    final arrived = visit.arrivedAt; // hora de llegada (null si se deshizo)
    return Column( // textos uno debajo de otro
      crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
      children: [
        Text( // hora de llegada
          arrived == null // si no hay hora (por ejemplo, se deshizo Llegué)
              ? 'Sin hora de llegada' // mensaje alterno
              : 'Llegaste a las ${formatClock(arrived)}', // ej. "Llegaste a las 8:20"
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), // grande y en negritas
        ),
        if (visit.companions.isNotEmpty) // si va con acompañantes
          Text( // los nombres
            'Con: ${visit.companions.map((c) => c.name).join(', ')}', // ej. "Con: Toño"
            style: const TextStyle(color: AppColors.gris600), // gris
          ),
      ],
    );
  }
}