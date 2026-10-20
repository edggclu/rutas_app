import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerStatefulWidget
import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/domain/rules/closing.dart';
import 'package:telyser_app/domain/rules/extras.dart';
import 'package:telyser_app/domain/rules/visit_state.dart';
import 'package:telyser_app/providers/route_providers.dart';

import '../../../core/theme/app_colors.dart'; // colores
import '../../../core/widgets/slide_to_confirm.dart'; // botón deslizable
import '../../closing/blocked_screen.dart'; // C7b
import '../../closing/continue_screen.dart'; // C7a
import '../../closing/finish_sheet.dart'; // C6
import '../../closing/not_finished_sheet.dart'; // C7
import '../../shared/run_undoable.dart'; // runUndoable y AfterSave

/// Barra de abajo de En sitio: "Terminé el trabajo" y "No lo terminé".
/// Decide sola si el técnico puede terminar (en garantía, solo si ya la documentó).
class CloseBar extends ConsumerStatefulWidget { // con estado: guarda las llaves de los deslizables
  const CloseBar({super.key, required this.visitId}); // recibe solo el id

  final int visitId; // id de la visita

  @override
  ConsumerState<CloseBar> createState() => _CloseBarState(); // crea el estado
}

class _CloseBarState extends ConsumerState<CloseBar> { // el estado de la barra
  final _finishKey = GlobalKey<SlideToConfirmState>(); // para regresar "Terminé" si se cancela
  final _notKey = GlobalKey<SlideToConfirmState>(); // para regresar "No lo terminé" si se cancela

  int get _id => widget.visitId; // atajo al id de la visita

  /// Desliza "Terminé el trabajo": si hubo extras, primero los confirma el contacto.
  Future<void> _finish() async { // se ejecuta al completar el deslizamiento
    final events = ref.read(visitEventsProvider).value ?? const <VisitEvent>[]; // las acciones de la cola
    final extras = extrasOf(events, _id); // extras de esta visita
    if (extras.isEmpty) { // sin extras no hay nada que confirmar
      await _doFinish(); // cierra directo
      return; // termina
    }
    final visit = ref.read(visitByIdProvider(_id)); // la visita actual
    final who = await showFinishSheet( // muestra la hoja de confirmación
      context, // sobre esta pantalla
      extras: extras, // los extras
      contactName: visit?.place.contact?.name, // nombre del contacto autorizado, como ayuda
    );
    if (!mounted) return; // si ya cerró la pantalla, termina
    if (who == null) { // el técnico canceló
      _finishKey.currentState?.reset(); // regresa el deslizable
      return; // termina
    }
    await _doFinish(who); // cierra con la confirmación
  }

  /// Guarda el cierre en la cola y regresa a Mi día.
  Future<void> _doFinish([FinishConfirmation? who]) async { // who = quién confirmó los extras (null si no hubo)
    await runUndoable( // guarda, cierra y muestra la barra
      context, ref, // dónde mostrar los avisos
      action: (a) => a.closing.finish( // el área de cierre
        visitId: _id, // visita
        confirmedBy: who?.name, // quién confirmó los extras
        confirmedRole: who?.role, // su cargo
      ),
      message: 'Marcaste Terminé el trabajo', // texto de la barra
      after: AfterSave.popToRoot, // vuelve a Mi día
      onError: () => _finishKey.currentState?.reset(), // regresa el deslizable
    );
  }

  /// Desliza "No lo terminé": pregunta cuál de las dos opciones y abre su pantalla.
  Future<void> _notFinished() async { // se ejecuta al completar el deslizamiento
    final choice = await showNotFinishedSheet(context); // muestra la hoja con las dos opciones
    if (!mounted) return; // si ya cerró la pantalla, termina
    if (choice == null) { // volvió a la visita
      _notKey.currentState?.reset(); // regresa el deslizable
      return; // termina
    }
    final visit = ref.read(visitByIdProvider(_id)); // la visita actual
    if (visit == null) return; // sin visita no hay nada que hacer
    await Navigator.of(context).push( // abre la pantalla elegida y espera a que se cierre
      MaterialPageRoute<void>(
        builder: (_) => choice == NotFinishedChoice.continueTomorrow // según la opción
            ? ContinueScreen(visit: visit) // Sigo otro día
            : BlockedScreen(visit: visit), // No pude seguir
      ),
    );
    if (mounted) _notKey.currentState?.reset(); // si regresó sin enviar, regresa el deslizable
  }

  @override
  Widget build(BuildContext context) { // dibuja la barra
    final visit = ref.watch(visitByIdProvider(_id)); // la visita con su estado actual
    final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[]; // las acciones de la cola
    final isWarranty = visit?.job.coverage == Coverage.warranty; // ¿es una visita de garantía?
    final canFinish = !isWarranty || warrantyDocumented(events, _id); // en garantía, solo si ya la documentó
    final bottom = MediaQuery.of(context).padding.bottom; // alto de la barra de gestos
    return Container( // franja blanca de abajo
      color: Colors.white, // fondo blanco
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8 + bottom), // margen interno
      child: Column( // elementos uno debajo de otro
        mainAxisSize: MainAxisSize.min, // solo ocupa lo necesario
        children: [
          if (!canFinish) // en garantía sin documentar
            const Padding( // aviso con margen abajo
              padding: EdgeInsets.only(bottom: 8), // 8 de margen inferior
              child: Text( // texto del aviso
                'Documenta la garantía para poder terminar.', // mensaje
                textAlign: TextAlign.center, // centrado
                style: TextStyle(color: AppColors.alerta, fontSize: 12), // ámbar y pequeño
              ),
            ),
          SlideToConfirm( // el deslizable grande
            key: _finishKey, // para poder regresarlo
            enabled: canFinish, // deshabilitado si falta la garantía
            color: AppColors.ok, // verde
            label: 'Desliza: Terminé el trabajo', // texto
            onConfirmed: _finish, // al completarlo, cierra (con confirmación si hubo extras)
          ),
          const SizedBox(height: 8), // espacio vertical
          SlideToConfirm( // el deslizable chico
            key: _notKey, // para poder regresarlo
            height: 48, // más bajo que el principal
            color: AppColors.navy500, // gris azulado
            label: 'Desliza: No lo terminé', // texto
            onConfirmed: _notFinished, // al completarlo, pregunta qué pasó
          ),
        ],
      ),
    );
  }
}