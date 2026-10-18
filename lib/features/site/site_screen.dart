import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telyser_app/core/theme/app_colors.dart';
import 'package:telyser_app/core/time/time_utils.dart';
import 'package:telyser_app/core/widgets/alert_box.dart';
import 'package:telyser_app/core/widgets/app_header.dart';
import 'package:telyser_app/core/widgets/slide_to_confirm.dart';
import 'package:telyser_app/core/widgets/undo_bar.dart';
import 'package:telyser_app/data/local/app_database.dart';
import 'package:telyser_app/data/providers.dart';
import 'package:telyser_app/domain/enums.dart';
import 'package:telyser_app/domain/event_types.dart';
import 'package:telyser_app/domain/visit_state.dart';
import 'package:telyser_app/features/my_day/visit_tags.dart';
import 'package:telyser_app/features/no_answer/no_answer.dart';

/// En sitio: pantalla de trabajo durante la visita.
class SiteScreen extends ConsumerWidget { 
  const SiteScreen({super.key, required this.visitId}); 

  final int visitId; // id de la visita

  void _toast(BuildContext context, String msg) => 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// Abre la camara y guarda la foto en el teléfono. / se ejecuta al tocar "Tomar foto"
  Future<void> _takePhoto(BuildContext context, WidgetRef ref) async { 
    final messenger = ScaffoldMessenger.of(context); 
    final repo = ref.read(mediaRepositoryProvider); // el repositorio de fotos
    try { 
      final shot = await ImagePicker().pickImage( // abre la cámara y espera la foto
        source: ImageSource.camera, // usar la cámara y no la galería
        maxWidth: 1600, // reduce el ancho máximo para que pese poco
        imageQuality: 70, // calidad JPEG de 0 a 100
      );
      if (shot == null) return; // el técnico canceló tomar la foto y no se guarda nada
      await repo.addPhoto(visitId: visitId, sourcePath: shot.path); // copia la foto y la deja pendiente de subir
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('No se pudo guardar la foto. Intenta de nuevo.'), 
      ));
    }
  }

  /// Desliza "Termine el trabajo": cierra la visita y regresa a Mi día.
  Future<void> _finish(BuildContext context, WidgetRef ref) async { 
    final messenger = ScaffoldMessenger.of(context); 
    final navigator = Navigator.of(context); 
    final actions = ref.read(visitActionsProvider); 
    try { 
      final receipt = await actions.finish(visitId: visitId); 
      navigator.popUntil((route) => route.isFirst); // vuelve a Mi día
      showUndoBar( 
        messenger, 
        message: 'Marcaste Terminé el trabajo', 
        seconds: receipt.graceSeconds, 
        onUndo: () => actions.undo(receipt), // si toca Deshacer, se borra de la cola
      );
    } catch (_) { 
      messenger.showSnackBar(const SnackBar( 
        content: Text('No se pudo guardar. Intenta de nuevo.'), 
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { 
    final visit = ref.watch(visitByIdProvider(visitId)); 
    final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[]; // las acciones de la cola
    final photos = ref.watch(mediaForVisitProvider(visitId)).value ?? const <MediaQueueData>[]; // las fotos de esta visita
    if (visit == null) { 
      return const Scaffold(body: Center(child: CircularProgressIndicator())); 
    }

    // alguna vez aviso que nadie abria?
    final reportedNoAnswer = events.any( 
        (e) => e.visitId == visitId && e.type == EventTypes.noAnswerReported); 
    final arrived = visit.arrivedAt; // hora de llegada
    final isWarranty = visit.job.coverage == Coverage.warranty; // verifica si es una visita de garantia
    final bottom = MediaQuery.of(context).padding.bottom; 

    return Scaffold( 
      body: Column(
        children: [
          AppHeader( 
            subtitle: visit.job.folio, 
            title: visit.place.name, 
            onBack: () => Navigator.of(context).pop(), 
            bottom: Wrap( 
              spacing: 6, 
              runSpacing: 6, 
              children: [...visitTags(visit.job), statusChip(visit.status)], // tipo, urgente, cobertura y estado
            ),
          ),
          Expanded( 
            child: ListView( 
              padding: const EdgeInsets.all(16), 
              children: [
                if (reportedNoAnswer) ...[ // si en algún momento avisó que nadie abría
                  const AlertBox( 
                    title: 'Aviso a la oficina', 
                    body: 'Reportaste que nadie abría.', 
                    background: AppColors.alertaSuave, 
                    foreground: AppColors.alerta, 
                  ),
                  Align( 
                    alignment: Alignment.centerLeft, 
                    child: TextButton( 
                      onPressed: () => Navigator.of(context).push( 
                        MaterialPageRoute<void>( 
                          builder: (_) => NoAnswerScreen(visitId: visitId), 
                        ),
                      ),
                      child: const Text('Ver espera >'), 
                    ),
                  ),
                  const SizedBox(height: 4), 
                ],
                Text( 
                  arrived == null 
                      ? 'Sin hora de llegada' 
                      : 'Llegaste a las ${formatClock(arrived)}', // ejemplo : "Llegaste a las 8:20"
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), 
                ),
                if (visit.companions.isNotEmpty) // si va con acompañantes
                  Text( 
                    'Con: ${visit.companions.map((c) => c.name).join(', ')}', 
                    style: const TextStyle(color: AppColors.gris600), 
                  ),
                const SizedBox(height: 16), 
                Row( 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    const Text( 
                      'Fotos', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700), 
                    ),
                    Text( 
                      '${photos.length}', 
                      style: const TextStyle(color: AppColors.gris600, fontWeight: FontWeight.w600), 
                    ),
                  ],
                ),
                const SizedBox(height: 8), 
                FilledButton.icon( // botón: tomar foto
                  onPressed: () => _takePhoto(context, ref), // abre la cámara
                  icon: const Icon(Icons.photo_camera), // ícono de cámara
                  label: const Text('Tomar foto'), 
                ),
                const SizedBox(height: 10), 
                if (photos.isEmpty) // si todavía no hay fotos
                  const Text( 
                    'Todavía no hay fotos.', 
                    style: TextStyle(color: AppColors.gris600),
                  )
                else // si ya hay fotos
                  SizedBox( 
                    height: 84, // alto de cada miniatura
                    child: ListView.separated( 
                      scrollDirection: Axis.horizontal, 
                      itemCount: photos.length, 
                      separatorBuilder: (context, index) => const SizedBox(width: 8), 
                      itemBuilder: (context, i) => _Thumb(photo: photos[i]), // dibuja cada miniatura
                    ),
                  ),
                const SizedBox(height: 16), 
                Row( 
                  children: [
                    Expanded( 
                      child: OutlinedButton( 
                        onPressed: () => _toast(context, 'Los extras llegan en el bloque 4b.'), 
                        child: const Text('+ Extra'), 
                      ),
                    ),
                    const SizedBox(width: 8), 
                    Expanded( // segunda mitad
                      child: OutlinedButton( 
                        onPressed: () => _toast(context, 'Las solicitudes llegan en el bloque 4b.'), 
                        child: const Text('Solicitud después'), 
                      ),
                    ),
                  ],
                ),
                if (!visit.responsible) ...[ 
                  const SizedBox(height: 16), 
                  const AlertBox( 
                    title: 'Eres acompañante', 
                    body: 'Puedes subir fotos. El responsable cierra la visita.', 
                  ),
                ],
              ],
            ),
          ),
          if (visit.responsible) // solo el responsable ve los botones de cierre
            Container( 
              color: Colors.white, 
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8 + bottom), 
              child: Column( 
                mainAxisSize: MainAxisSize.min, 
                children: [
                  if (isWarranty) 
                    const Padding( 
                      padding: EdgeInsets.only(bottom: 8), 
                      child: Text( 
                        'En garantía, el bloque de garantía es obligatorio antes de terminar (llega en 4c).', 
                        textAlign: TextAlign.center, 
                        style: TextStyle(color: AppColors.alerta, fontSize: 12), 
                      ),
                    ),
                  SlideToConfirm( // el deslizable grande
                    enabled: !isWarranty, // deshabilitado en garantía
                    color: AppColors.ok, 
                    label: 'Desliza: Terminé el trabajo', 
                    onConfirmed: () => _finish(context, ref),
                  ),
                  TextButton( // botón chico: no lo termine
                    onPressed: () => _toast(context, 'No lo terminé llega en el bloque 4c.'), 
                    child: const Text('No lo terminé'), 
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