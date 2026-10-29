import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/providers/route_providers.dart';

import '../../core/widgets/alert_box.dart';
import '../../core/widgets/app_header.dart';
import '../my_day/visit_tags.dart';
import 'widgets/close_bar.dart';
import 'widgets/extras_section.dart';
import 'widgets/photos_section.dart';
import 'widgets/site_info.dart';
import 'widgets/warranty_section.dart';

/// C5 · En sitio: pantalla de trabajo durante la visita.
/// Solo compone las secciones; cada una lee lo que necesita y se redibuja sola.
class SiteScreen extends ConsumerWidget { // widget que puede leer providers
  const SiteScreen({super.key, required this.visitId}); // recibe solo el id de la visita

  final int visitId; // id de la visita

  @override
  Widget build(BuildContext context, WidgetRef ref) { // dibuja la pantalla
    final visit = ref.watch(visitByIdProvider(visitId)); // la visita con su estado actual
    if (visit == null) { // todavía no carga
      return const Scaffold(body: Center(child: CircularProgressIndicator())); // círculo de carga
    }
    final isWarranty = visit.job.coverage == Coverage.warranty; // ¿es una visita de garantía?

    return Scaffold( // estructura de la pantalla
      body: Column( // elementos uno debajo de otro
        children: [
          AppHeader( // encabezado navy
            subtitle: visit.job.folio, // arriba: el folio
            title: visit.place.name, // título: el lugar
            onBack: () => Navigator.of(context).pop(), // flecha para regresar
            bottom: Wrap( // etiquetas en fila
              spacing: 6, // espacio horizontal entre etiquetas
              runSpacing: 6, // espacio vertical si bajan de renglón
              children: [...visitTags(visit.job), visitStatusChip(visit)], // tipo, urgente, cobertura y estado
            ),
          ),
          Expanded( // ocupa el espacio que queda
            child: ListView( // contenido que se puede desplazar
              padding: const EdgeInsets.all(16), // margen de 16
              children: [
                NoAnswerBanner(visitId: visitId), // aviso de "No me abren" (si se reportó)
                ArrivalInfo(visit: visit), // hora de llegada y acompañantes
                if (isWarranty) ...[ // en visitas de garantía
                  const SizedBox(height: 16), // espacio vertical
                  WarrantySection(visit: visit), // tarjeta de garantía
                ],
                const SizedBox(height: 16), // espacio vertical
                PhotosSection(visitId: visitId), // fotos de avance
                const SizedBox(height: 16), // espacio vertical
                ExtrasSection(visit: visit), // extras y solicitudes
                if (!visit.responsible) ...[ // si es acompañante (no responsable)
                  const SizedBox(height: 16), // espacio vertical
                  const AlertBox( // aviso
                    title: 'Eres acompañante', // título
                    body: 'Puedes subir fotos. El responsable cierra la visita.', // texto
                  ),
                ],
              ],
            ),
          ),
          if (visit.responsible) CloseBar(visitId: visitId), // solo el responsable ve los botones de cierre
        ],
      ),
    );
  }
}