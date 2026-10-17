import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/core/theme/app_colors.dart';
import 'package:telyser_app/core/time/time_utils.dart';
import 'package:telyser_app/core/widgets/app_header.dart';
import 'package:telyser_app/data/providers.dart';
import 'package:telyser_app/features/my_day/visit_tags.dart';

/// En sitio (provisional). Muestra la visita con su estado en vivo.
class SiteScreen extends ConsumerWidget{ // widget que puede leer providers

  final int visitId;

  const SiteScreen({super.key, required this.visitId}); // id de la visita que se muestra


  @override
  Widget build(BuildContext context, WidgetRef ref) { // ref es acceso a los providers
    final visit = ref.watch(visitByIdProvider(visitId));
    if(visit==null) {
      // círculo de carga
      return const Scaffold(body: Center(child: CircularProgressIndicator(),));
    }
    final arrived = visit.arrivedAt;
    return Scaffold(
      body: Column(
        children: [
          // Encabezado
          AppHeader(
            subtitle: visit.job.folio, // folio
            title: visit.place.name, 
            onBack: () => Navigator.of(context).pop(), // flecha para regresar
            bottom: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [...visitTags(visit.job), statusChip(visit.status)], // tipo, urgente, cobertura y estado
            ),
          ),
          // Resto de la pantalla
          Expanded(child: Center(
            child: 
              Padding(padding: const EdgeInsets.all(32), // padding de 32 en cada lado
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      arrived == null // si no hay hora (por ejemplo, se deshizo)
                        ? 'Sin hora de llegada'
                        : 'Llegaste a las ${formatClock(arrived)}', // "Llegaste a las 8:20"
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,)
                    ),
                    const SizedBox(height: 8,),

                    const Text(
                      'TODO: Aqui iran las fotos, los extras y el cierre de la visita',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gris600),
                    )
                  ],
                ),
              ),
            )
          )
        ],
      ),
    );
  } 
}