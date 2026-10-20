import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/providers/actions.provider.dart';

import '../../core/theme/app_colors.dart'; // colores
import '../../core/widgets/alert_box.dart'; // caja de aviso
import '../../core/widgets/app_header.dart'; // encabezado navy
import '../../core/widgets/slide_to_confirm.dart'; // botón deslizable
import '../../core/widgets/toast.dart'; // avisos cortos
import '../no_answer/no_answer_screen.dart'; // pantalla "No me abren"
import '../shared/run_undoable.dart'; // runUndoable
import '../site/site_screen.dart'; // pantalla En sitio
import 'arrival_panel.dart'; // el panel "¿Ya te abrieron?"
import 'visit_tags.dart'; // etiquetas (tipo, urgente, estado)
import 'widgets/address_card.dart'; // dirección y mapa
import 'widgets/contact_card.dart'; // contacto
import 'widgets/task_card.dart'; // qué hay que hacer

/// C3 · Tarjeta de visita: todo lo necesario para llegar y saber qué hacer.
/// Abajo muestra el deslizable "Llegué" o, si ya llegó, el panel "¿Ya te abrieron?".
class VisitDetailScreen extends ConsumerWidget { // ConsumerWidget: puede leer providers con `ref`
  const VisitDetailScreen({super.key, required this.visit}); // recibe la visita

  final Visit visit; // la visita que se muestra

  Future<void> _arrive(BuildContext context, WidgetRef ref) async { // se ejecuta al deslizar "Llegué"
    await runUndoable( // guarda y muestra la barra
      context, ref, // dónde mostrar los avisos
      action: (a) => a.arrival.arrive(visitId: visit.id), // el área de llegada: lee el GPS y guarda
      message: 'Marcaste Llegué', // texto de la barra
      errorMessage: 'No se pudo guardar tu llegada. Intenta de nuevo.', // texto del error
    );
  }

  /// "No me abren": avisa a la oficina (sin deshacer) y abre la cuenta regresiva.
  Future<void> _noAnswer(BuildContext context, WidgetRef ref) async { // se ejecuta al tocar "No me abren" en el panel
    final navigator = Navigator.of(context); // se guarda antes del await
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    try { // si algo falla, se avisa
      await ref.read(visitActionsProvider).noAnswer.reportNoAnswer(visitId: visit.id); // avisa a la oficina (una sola vez)
      navigator.push( // abre la pantalla C4
        MaterialPageRoute<void>( // pantalla nueva
          builder: (_) => NoAnswerScreen(visitId: visit.id), // con el id de esta visita
        ),
      );
    } catch (_) { // no se pudo guardar el aviso
      messenger.toast('No se pudo guardar. Intenta de nuevo.'); // aviso
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { // dibuja la pantalla
    final job = visit.job; // el trabajo
    final place = visit.place; // el lugar
    final contact = place.contact; // contacto principal (puede faltar)
    final bottom = MediaQuery.of(context).padding.bottom; // alto de la barra de gestos

    return Scaffold( // estructura de la pantalla
      body: Column( // elementos uno debajo de otro
        children: [
          AppHeader( // encabezado navy
            subtitle: job.folio, // arriba: el folio
            title: place.name, // título: el lugar
            onBack: () => Navigator.of(context).pop(), // flecha para regresar
            bottom: Wrap( // etiquetas en fila
              spacing: 6, // espacio horizontal entre etiquetas
              runSpacing: 6, // espacio vertical si bajan de renglón
              children: [...visitTags(job), statusChip(visit.status)], // tipo, urgente, cobertura y estado
            ),
          ),
          Expanded( // ocupa el espacio que queda
            child: ListView( // contenido que se puede desplazar
              padding: const EdgeInsets.all(16), // margen de 16
              children: [
                AddressCard(place: place), // dirección y botón de mapa
                const SizedBox(height: 10), // espacio vertical
                if (contact != null) ContactCard(contact: contact), // contacto, si lo hay
                if (place.accessNotes != null) ...[ // si hay notas de acceso
                  const SizedBox(height: 10), // espacio vertical
                  AlertBox(title: 'Notas de acceso', body: place.accessNotes!), // las notas
                ],
                const SizedBox(height: 10), // espacio vertical
                TaskCard(job: job), // qué hay que hacer
                if (visit.client.overdue) ...[ // si el cliente tiene saldo vencido
                  const SizedBox(height: 10), // espacio vertical
                  const AlertBox( // aviso ámbar (sin montos)
                    title: 'Saldo vencido', // título
                    body: 'Este cliente tiene saldo vencido. No agregues equipo sin autorización.', // texto
                    background: AppColors.alertaSuave, // fondo ámbar claro
                    foreground: AppColors.alerta, // texto ámbar
                  ),
                ],
                if (job.coverage == Coverage.warranty && job.warrantyGuide != null) ...[ // si es garantía y hay guía
                  const SizedBox(height: 10), // espacio vertical
                  AlertBox( // la guía
                    title: 'Guía de garantía', // título
                    body: job.warrantyGuide!, // texto de la guía
                    background: AppColors.alertaSuave, // fondo ámbar claro
                    foreground: AppColors.alerta, // texto ámbar
                  ),
                ],
              ],
            ),
          ),
          if (visit.status == VisitStatus.onSite) // si ya llegó (estado calculado con la cola)
            ArrivalPanel( // muestra "¿Ya te abrieron?"
              visit: visit, // la visita
              onStart: () => Navigator.of(context).push( // al tocar "Empezar"
                MaterialPageRoute<void>( // abre una pantalla nueva
                  builder: (_) => SiteScreen(visitId: visit.id), // la pantalla En sitio
                ),
              ),
              onNoAnswer: () => _noAnswer(context, ref), // al tocar "No me abren": avisa y abre C4
            )
          else if (visit.status != VisitStatus.done) // si no ha llegado y la visita no está terminada
            Container( // caja blanca que contiene el deslizable
              color: Colors.white, // fondo blanco
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom), // margen interno (deja espacio para la barra de gestos)
              child: SlideToConfirm( // el deslizable
                label: 'Desliza: Llegué', // texto
                onConfirmed: () => _arrive(context, ref), // al completar el deslizamiento, marca la llegada
              ),
            ),
        ],
      ),
    );
  }
}