import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/core/contact_launcher.dart';
import 'package:telyser_app/core/theme/app_colors.dart';
import 'package:telyser_app/core/widgets/app_header.dart';
import 'package:telyser_app/core/widgets/slide_to_confirm.dart';
import 'package:telyser_app/core/widgets/undo_bar.dart';
import 'package:telyser_app/data/providers.dart';
import 'package:telyser_app/domain/models.dart';
import 'package:telyser_app/domain/no_answer.dart';
import 'package:telyser_app/domain/visit_state.dart';

/// Muestra los kilometros sin .0 cuando son enteros 
String _kmLabel(double? km) {
  if(km == null) return '0';
  return km % 1==0 ? km.toInt().toString() : km.toStringAsFixed(1); // enseña el entero sin decimales, si tiene solo enseña  1
}

/// No me abren / Cuenta regresiva / intentos de contacto y salida
class NoAnswerScreen extends ConsumerWidget {

  final int visitId;

  const NoAnswerScreen({super.key, required this.visitId});

  /// Formatea una duración como mm:ss
  String _clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0'); // minutos totales, con dos dígitos
    final s = (d.inSeconds % 60).toString().padLeft(2, '0'); // segundos
    return '$m$s';
  }

  /// Llamar o whatsapp registra intento si se abrio la app
  /// Se ejecuta al tocar los botones
  Future<void> _contactClient(
    BuildContext context, WidgetRef ref, Visit visit, String channel) async { // channel: 'call' o 'whatsapp'
    final phone = visit.place.contact?.phone; // teléfono del contacto del lugar
    if (phone == null || phone.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    final actions = ref.read(visitActionsProvider); // las acciones del técnico
    final ok = channel == 'call' // según el canal elegido abre el marcador o whatsapp
        ? await callPhone(phone) 
        : await openWhatsApp(phone); 
    if (!ok) { 
      messenger.showSnackBar(const SnackBar( 
        content: Text('No se pudo abrir la aplicación.'), 
      ));
      return; // no se registra un intento que no ocurrió
    }
    await actions.registerClientContact(visitId: visit.id, channel: channel); // guarda el intento en la cola
  }

  /// Llamar a la oficina, registra el intento si se abrió el marcador.
  /// se ejecuta al tocar "Llamar a la oficina"
  Future<void> _callOffice( 
      BuildContext context, WidgetRef ref, Visit visit, String officePhone) async { 
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(visitActionsProvider);
    final ok = await callPhone(officePhone); // abre el marcador con el número de la oficina
    if (!ok) { // no se pudo abrir
      messenger.showSnackBar(const SnackBar(
        content: Text('No se pudo abrir el teléfono.'), 
      ));
      return; // no se registra
    }
    await actions.registerOfficeCall(visitId: visit.id); // guarda el intento en la cola
  }

  /// Desliza "No me atendieron", cierra la visita y regresa a Mi día.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final actions = ref.read(visitActionsProvider); // las acciones del técnico
    try {
      final receipt = await actions.confirmNoAnswer(visitId: visitId); // guarda el cierre en la cola
      navigator.popUntil((route) => route.isFirst); // vuelve a mi dia
      showUndoBar( // barra con cuenta regresiva
        messenger, 
        message: 'Marcaste No me atendieron', // texto
        seconds: receipt.graceSeconds,
        onUndo: () => actions.undo(receipt),
      );
    } catch (_) { // no se pudo guardar
      messenger.showSnackBar(const SnackBar( 
        content: Text('No se pudo guardar. Intenta de nuevo.'), 
      ));
    }
  }

  // dibuja la pantalla
  @override
  Widget build(BuildContext context, WidgetRef ref) { 
    final visit = ref.watch(visitByIdProvider(visitId));
    final settings = ref.watch(settingsProvider).value; // los parámetros , politicas 
    final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[]; // las acciones de la cola
    final now = ref.watch(tickProvider).value ?? DateTime.now().toUtc(); // la hora, cambia cada segundo
    if (visit == null || settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator())); // círculo de carga
    }

    // calcula si le falta al técnico
    final status = computeNoAnswerStatus( 
        visit: visit, events: events, settings: settings, now: now);
    final phone = visit.place.contact?.phone; // teléfono del cliente
    final hasPhone = phone != null && phone.isNotEmpty; 
    final bottom = MediaQuery.of(context).padding.bottom; 

    return Scaffold( 
      body: Column(
        children: [
          AppHeader( // encabezado navy
            subtitle: visit.job.folio, 
            title: 'No me abren',
            onBack: () => Navigator.of(context).pop(), // flecha para regresar a la tarjeta
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CountdownCard( // la cuenta regresiva grande, esta clase esta abajo
                  status: status,
                  baseMin: settings.waitBaseMin, // minutos base
                  perKm: settings.waitPerKmMin, // minutos por km
                  clock: _clock(status.remaining), // el tiempo que falta ya formateado
                ),
                const SizedBox(height: 12),
                _RequirementsCard(status: status), // tambien esta abajo esta clase
                const SizedBox(height: 12), 
                // boton de llamar al cliente
                OutlinedButton( 
                  onPressed: hasPhone 
                      ? () => _contactClient(context, ref, visit, 'call') 
                      : null,
                  child: const Text('Llamar al cliente'), 
                ),
                const SizedBox(height: 8), 
                // boton de whatsapp al cliente
                OutlinedButton( 
                  onPressed: hasPhone // solo si hay teléfono
                      ? () => _contactClient(context, ref, visit, 'whatsapp')
                      : null, 
                  child: const Text('WhatsApp al cliente'), 
                ),
                const SizedBox(height: 8), 
                // boton de llamar a la oficina
                OutlinedButton( 
                  onPressed: () => _callOffice(context, ref, visit, settings.officePhone), 
                  child: const Text('Llamar a la oficina'), 
                ),
                // si el lugar no tiene teléfono de contacto
                if (!hasPhone) 
                  const Padding( 
                    padding: EdgeInsets.only(top: 8), 
                    child: Text( 
                      'Este lugar no tiene teléfono de contacto.', 
                      style: TextStyle(color: AppColors.gris600, fontSize: 12), 
                    ),
                  ),
              ],
            ),
          ),
          // franja blanca de abajo 
          Container( 
            color: Colors.white, 
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom), 
            child: SlideToConfirm( 
              enabled: status.canLeave, // se activa solo cuando se cumplen las tres condiciones
              label: 'Desliza: No me atendieron', 
              onConfirmed: () => _confirm(context, ref), // al completarlo, cierra la visita
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con la cuenta regresiva grande.
class _CountdownCard extends StatelessWidget { 
  const _CountdownCard({ 
    required this.status, 
    required this.baseMin,
    required this.perKm, // minutos por km
    required this.clock, // el tiempo que falta mm:ss
  });

  final NoAnswerStatus status; 
  final int baseMin; 
  final int perKm; 
  final String clock; 

  @override
  Widget build(BuildContext context) { 
    return Container( 
      width: double.infinity, 
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration( 
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), // esquinas redondeadas
        border: Border.all(color: AppColors.gris200), 
      ),
      child: Column( 
        children: [
          Text( 
            status.timeDone ? 'Tiempo cumplido' : 'Tiempo de espera', // cambia al terminar
            style: const TextStyle(color: AppColors.gris600, fontWeight: FontWeight.w600), 
          ),
          const SizedBox(height: 4), 
          // la cuenta regresiva mm:ss
          Text( 
            clock, 
            style: TextStyle( 
              fontSize: 56,
              fontWeight: FontWeight.w700, 
              color: status.timeDone ? AppColors.ok : AppColors.navy900, // verde al terminar, navy mientras corre
            ),
          ),
          const SizedBox(height: 4),
          // como se calculó la espera
          Text( 
            '$baseMin min base + ${_kmLabel(status.km)} km x $perKm min = ${status.wait.inMinutes} min', // "10 min base + 5 km × 1 min = 15 min"
            textAlign: TextAlign.center, 
            style: const TextStyle(color: AppColors.gris600, fontSize: 12), 
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con los tres requisitos para poder irse.
class _RequirementsCard extends StatelessWidget { 
  const _RequirementsCard({required this.status}); 

  // el estado calculado
  final NoAnswerStatus status; 

  @override
  Widget build(BuildContext context) { 
    return Container( 
      width: double.infinity, 
      padding: const EdgeInsets.all(14), 
      decoration: BoxDecoration( 
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: AppColors.gris200), 
      ),
      child: Column( 
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          const Text( 
            'Para poder irte necesitas', 
            style: TextStyle(fontWeight: FontWeight.w700), 
          ),
          const SizedBox(height: 8), 

          // Rwquisitos, 1: contactos al cliente / 2: llamada / 3: tiempo esperado
          _RequirementRow( 
            label: 'Contactar al cliente', 
            detail: '${status.clientContacts}/${status.clientContactsNeeded}', 
            done: status.clientOk, 
          ),
          _RequirementRow( 
            label: 'Llamar a la oficina', 
            detail: '${status.officeCalls}/${status.officeCallsNeeded}', 
            done: status.officeOk, 
          ),
          _RequirementRow( 
            label: 'Esperar el tiempo', 
            detail: status.timeDone ? 'Listo' : 'En curso', 
            done: status.timeDone, 
          ),
        ],
      ),
    );
  }
}

/// Una fila, palomita verde si está cumplido, gris si no, texto y detalle.
class _RequirementRow extends StatelessWidget { 
  const _RequirementRow({ 
    required this.label, 
    required this.detail, 
    required this.done, 
  });

  final String label; 
  final String detail; 
  final bool done; // true = cumplido

  @override
  Widget build(BuildContext context) { 
    return Padding( 
      padding: const EdgeInsets.symmetric(vertical: 6), 
      child: Row( 
        children: [
          Icon( 
            done ? Icons.check_circle : Icons.radio_button_unchecked, 
            size: 20, 
            color: done ? AppColors.ok : AppColors.gris400, 
          ),
          const SizedBox(width: 10), 
          Expanded(child: Text(label)), 
          Text( 
            detail, 
            style: const TextStyle( 
              fontSize: 13, 
              fontWeight: FontWeight.w600, // seminegritas 
              color: AppColors.gris600, 
            ),
          ),
        ],
      ),
    );
  }
}
