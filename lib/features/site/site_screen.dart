import 'dart:io'; // File: para mostrar las fotos guardadas en el teléfono

import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerStatefulWidget
import 'package:telyser_app/features/closing/not_finished_sheet.dart';
import 'package:telyser_app/features/no_answer/no_answer.dart';
import 'package:telyser_app/features/shared/run_undoable.dart';
import 'package:telyser_app/providers/route_providers.dart';

import '../../core/theme/app_colors.dart'; // colores
import '../../core/time/time_utils.dart'; // formatClock
import '../../core/widgets/alert_box.dart'; // caja de aviso
import '../../core/widgets/app_header.dart'; // encabezado navy
import '../../core/widgets/slide_to_confirm.dart'; // botón deslizable
import '../../data/local/app_database.dart'; // MediaQueueData (una foto guardada)
import '../../domain/closing.dart'; // warrantyDocumented, lastWarrantyCause
import '../../domain/enums.dart'; // Coverage
import '../../domain/extras.dart'; // extrasOf y requestsOf
import '../../domain/events/event_data.dart';
import '../../domain/visit_state.dart'; // VisitEvent
import '../closing/blocked_screen.dart'; // C7b
import '../closing/continue_screen.dart'; // C7a
import '../closing/finish_sheet.dart'; // C6
import '../extras/add_extra_screen.dart'; // el formulario de extras
import '../extras/add_request_screen.dart'; // el formulario de solicitudes
import '../my_day/visit_tags.dart'; // etiquetas (tipo, urgente, estado)
import 'capture_photo.dart'; // capturePhoto
import 'warranty_card.dart'; // tarjeta de garantía
import 'warranty_screen.dart'; // pantalla de garantía

/// C5 · En sitio: pantalla de trabajo durante la visita.
class SiteScreen extends ConsumerStatefulWidget { // ahora con estado: guarda las llaves de los deslizables
  const SiteScreen({super.key, required this.visitId}); // recibe solo el id de la visita

  final int visitId; // id de la visita

  @override
  ConsumerState<SiteScreen> createState() => _SiteScreenState(); // crea el estado
}

class _SiteScreenState extends ConsumerState<SiteScreen> { // el estado de la pantalla
  final _finishKey = GlobalKey<SlideToConfirmState>(); // para regresar "Terminé" si se cancela
  final _notKey = GlobalKey<SlideToConfirmState>(); // para regresar "No lo terminé" si se cancela

  int get _id => widget.visitId; // atajo al id de la visita

  /// Abre la cámara y guarda la foto en el teléfono.
  Future<void> _takePhoto() async { // se ejecuta al tocar "Tomar foto"
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    try { // si algo falla, se avisa
      await capturePhoto(ref, visitId: _id); // abre la cámara y guarda
    } catch (_) { // la cámara falló o no se pudo guardar
      messenger.showSnackBar(const SnackBar( // aviso sencillo
        content: Text('No se pudo guardar la foto. Intenta de nuevo.'), // mensaje
      ));
    }
  }

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
  Widget build(BuildContext context) { // dibuja la pantalla
    final visit = ref.watch(visitByIdProvider(_id)); // la visita con su estado actual
    final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[]; // las acciones de la cola
    final photos = ref.watch(mediaForVisitProvider(_id)).value ?? const <MediaQueueData>[]; // los archivos de esta visita
    if (visit == null) { // todavía no carga
      return const Scaffold(body: Center(child: CircularProgressIndicator())); // círculo de carga
    }

    final extras = extrasOf(events, _id); // extras ya guardados de esta visita
    final requests = requestsOf(events, _id); // solicitudes ya guardadas de esta visita
    final reportedNoAnswer = events.any( // ¿alguna vez avisó que nadie abría?
        (e) => e.visitId == _id && e.type is NoAnswerReportedEvent); // acción de este tipo para esta visita
    final arrived = visit.arrivedAt; // hora de llegada (null si se deshizo)
    final isWarranty = visit.job.coverage == Coverage.warranty; // ¿es una visita de garantía?
    final documented = warrantyDocumented(events, _id); // ¿ya documentó la garantía?
    final canFinish = !isWarranty || documented; // en garantía, solo puede terminar si ya la documentó
    final shots = photos.where((m) => m.kind == 'progress').toList(); // solo las fotos de avance en la tira
    final bottom = MediaQuery.of(context).padding.bottom; // alto de la barra de gestos

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
              children: [...visitTags(visit.job), statusChip(visit.status)], // tipo, urgente, cobertura y estado
            ),
          ),
          Expanded( // ocupa el espacio que queda
            child: ListView( // contenido que se puede desplazar
              padding: const EdgeInsets.all(16), // margen de 16
              children: [
                if (reportedNoAnswer) ...[ // si en algún momento avisó que nadie abría
                  const AlertBox( // caja de aviso ámbar
                    title: 'Aviso a la oficina', // título
                    body: 'Reportaste que nadie abría.', // texto
                    background: AppColors.alertaSuave, // fondo ámbar claro
                    foreground: AppColors.alerta, // texto ámbar
                  ),
                  Align( // alinea el enlace a la izquierda
                    alignment: Alignment.centerLeft, // izquierda
                    child: TextButton( // botón de texto
                      onPressed: () => Navigator.of(context).push( // al tocarlo abre C4
                        MaterialPageRoute<void>( // pantalla nueva
                          builder: (_) => NoAnswerScreen(visitId: _id), // la pantalla de espera
                        ),
                      ),
                      child: const Text('Ver espera ›'), // texto del enlace
                    ),
                  ),
                  const SizedBox(height: 4), // espacio vertical
                ],
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
                if (isWarranty) ...[ // en visitas de garantía
                  const SizedBox(height: 16), // espacio vertical
                  WarrantyCard( // tarjeta con el estado de la garantía
                    documented: documented, // ¿ya se documentó?
                    causeLabel: lastWarrantyCause(events, _id)?.label, // causa guardada
                    onOpen: () => Navigator.of(context).push( // abre la pantalla de garantía
                      MaterialPageRoute<void>(
                        builder: (_) => WarrantyScreen(visit: visit), // con esta visita
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16), // espacio vertical
                Row( // título de fotos con su contador
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // uno a cada lado
                  children: [
                    const Text( // título
                      'Fotos', // texto
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700), // negritas
                    ),
                    Text( // contador
                      '${shots.length}', // cantidad de fotos de avance
                      style: const TextStyle(color: AppColors.gris600, fontWeight: FontWeight.w600), // gris
                    ),
                  ],
                ),
                const SizedBox(height: 8), // espacio vertical
                FilledButton.icon( // botón: tomar foto
                  onPressed: _takePhoto, // abre la cámara
                  icon: const Icon(Icons.photo_camera), // ícono de cámara
                  label: const Text('Tomar foto'), // texto
                ),
                const SizedBox(height: 10), // espacio vertical
                if (shots.isEmpty) // si todavía no hay fotos
                  const Text( // mensaje
                    'Todavía no hay fotos.', // texto
                    style: TextStyle(color: AppColors.gris600), // gris
                  )
                else // si ya hay fotos
                  SizedBox( // altura fija para la tira
                    height: 84, // alto de cada miniatura
                    child: ListView.separated( // lista horizontal con separadores
                      scrollDirection: Axis.horizontal, // se desliza de lado
                      itemCount: shots.length, // cuántas miniaturas
                      separatorBuilder: (context, index) => const SizedBox(width: 8), // espacio entre miniaturas
                      itemBuilder: (context, i) => _Thumb(photo: shots[i]), // dibuja cada miniatura
                    ),
                  ),
                const SizedBox(height: 16), // espacio vertical
                Row( // dos botones lado a lado
                  children: [
                    Expanded( // cada botón ocupa la mitad
                      child: OutlinedButton( // botón: extra
                        onPressed: () => Navigator.of(context).push( // abre el formulario
                          MaterialPageRoute<void>( // pantalla nueva
                            builder: (_) => AddExtraScreen(visit: visit), // con esta visita
                          ),
                        ),
                        child: const Text('+ Extra'), // texto
                      ),
                    ),
                    const SizedBox(width: 8), // espacio horizontal
                    Expanded( // segunda mitad
                      child: OutlinedButton( // botón: solicitud para después
                        onPressed: () => Navigator.of(context).push( // abre el formulario
                          MaterialPageRoute<void>( // pantalla nueva
                            builder: (_) => AddRequestScreen(visit: visit), // con esta visita
                          ),
                        ),
                        child: const Text('Solicitud después'), // texto
                      ),
                    ),
                  ],
                ),
                if (extras.isNotEmpty) ...[ // si ya registró extras
                  const SizedBox(height: 16), // espacio vertical
                  Text( // título de la lista
                    'Extras (${extras.length})', // con el contador
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), // negritas
                  ),
                  const SizedBox(height: 4), // espacio vertical
                  for (final x in extras) // por cada extra
                    _EntryRow( // un renglón
                      icon: Icons.add_circle_outline, // ícono
                      text: x.label, // ej. "1 × Cámara IP 4 MP"
                      tag: x.notInstalled ? 'No se instaló' : null, // etiqueta si es "no se instaló"
                    ),
                ],
                if (requests.isNotEmpty) ...[ // si ya guardó solicitudes
                  const SizedBox(height: 16), // espacio vertical
                  Text( // título de la lista
                    'Solicitudes para después (${requests.length})', // con el contador
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), // negritas
                  ),
                  const SizedBox(height: 4), // espacio vertical
                  for (final r in requests) // por cada solicitud
                    _EntryRow( // un renglón
                      icon: Icons.schedule, // ícono de reloj
                      text: r.description, // descripción
                          tag: r.origin == RequestOrigin.otherPerson // etiqueta según el origen
                          ? 'La pidió otra persona' // la pidió otra persona
                          : r.origin == RequestOrigin.creditHold // o saldo vencido
                              ? 'Saldo vencido' // el cliente tiene saldo vencido
                              : null, // si la creó el técnico, sin etiqueta, // si la creó el técnico, sin etiqueta
                    ),
                ],
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
          if (visit.responsible) // solo el responsable ve los botones de cierre
            Container( // franja blanca de abajo
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
            ),
        ],
      ),
    );
  }
}

/// Miniatura de una foto con un indicador: reloj (pendiente de subir) o nube (enviada).
class _Thumb extends StatelessWidget { 
  const _Thumb({required this.photo}); 

  final MediaQueueData photo; 

  @override
  Widget build(BuildContext context) { 
    final sent = photo.state == 'sent'; // revisa si ya se subio al servidor
    return Stack( // apila la imagen y el indicador
      children: [
        ClipRRect( 
          borderRadius: BorderRadius.circular(8), 
          child: Image.file( // muestra el archivo guardado en el telefono
            File(photo.localPath), // la ruta de la foto
            width: 84, 
            height: 84, 
            fit: BoxFit.cover, 
            cacheWidth: 168, 
            errorBuilder: (context, error, stack) => Container( // si el archivo no se puede leer
              width: 84, 
              height: 84, 
              color: AppColors.gris100, 
              child: const Icon(Icons.broken_image, color: AppColors.gris400), // ícono de imagen rota
            ),
          ),
        ),
        Positioned( 
          right: 4, 
          bottom: 4,
          child: Container( 
            padding: const EdgeInsets.all(3), 
            decoration: BoxDecoration( 
              color: sent ? AppColors.ok : AppColors.alerta, // verde si se subió, ambar si esta pendiente
              shape: BoxShape.circle, 
            ),
            child: Icon( 
              sent ? Icons.cloud_done : Icons.schedule, // nube si se subio, reloj si falta
              size: 14, 
              color: Colors.white, 
            ),
          ),
        ),
      ],
    );
  }
}

/// Un renglón de la lista de extras o solicitudes: ícono, texto y una etiqueta opcional.
class _EntryRow extends StatelessWidget { // widget sin estado propio
  const _EntryRow({required this.icon, required this.text, this.tag}); // constructor

  final IconData icon; // ícono de la izquierda
  final String text; // texto principal
  final String? tag; // etiqueta de la derecha (opcional)

  @override
  Widget build(BuildContext context) { // dibuja el renglón
    return Padding( // margen vertical
      padding: const EdgeInsets.symmetric(vertical: 4), // 4 arriba y abajo
      child: Row( // elementos en horizontal
        children: [
          Icon(icon, size: 18, color: AppColors.gris600), // el ícono
          const SizedBox(width: 8), // espacio horizontal
          Expanded(child: Text(text)), // el texto ocupa el espacio disponible
          if (tag != null) // si hay etiqueta
            Text( // la etiqueta
              tag!, // texto
              style: const TextStyle( // estilo
                fontSize: 12, // tamaño
                fontWeight: FontWeight.w700, // negritas
                color: AppColors.alerta, // ámbar
              ),
            ),
        ],
      ),
    );
  }
}