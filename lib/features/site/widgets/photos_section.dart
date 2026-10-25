
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/domain/models/media_item.dart';
import 'package:telyser_app/providers/route_providers.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/toast.dart';
import '../../media/media_strip.dart';
import '../capture_photo.dart';

/// Fotos de avance de la visita: contador, botón para tomar y tira de miniaturas.
/// Vigila solo sus fotos: al tomar una, no se redibuja el resto de la pantalla.
class PhotosSection extends ConsumerWidget { // widget que puede leer providers
  const PhotosSection({super.key, required this.visitId}); // recibe solo el id

  final int visitId; // id de la visita

  /// Abre la cámara y guarda la foto en el teléfono.
  Future<void> _take(BuildContext context, WidgetRef ref) async { // se ejecuta al tocar "Tomar foto"
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    try { // si algo falla, se avisa
      await capturePhoto(ref, visitId: visitId); // abre la cámara y guarda
    } catch (_) { // la cámara falló o no se pudo guardar
      messenger.toast('No se pudo guardar la foto. Intenta de nuevo.'); // aviso
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { // dibuja la sección
      final media = ref.watch(mediaForVisitProvider(visitId)).value ?? const <MediaItem>[]; // todos los archivos de la visita
    final shots = media.where((m) => m.kind == MediaKind.progress).toList(); // solo las fotos de avance

    return Column( // elementos uno debajo de otro
      crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
      children: [
        Row( // título con su contador
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
          onPressed: () => _take(context, ref), // abre la cámara
          icon: const Icon(Icons.photo_camera), // ícono de cámara
          label: const Text('Tomar foto'), // texto
        ),
        const SizedBox(height: 10), // espacio vertical
        if (shots.isEmpty) // si todavía no hay fotos
          const Text( // mensaje
            'Todavía no hay fotos.', // texto
            style: TextStyle(color: AppColors.gris600), // gris
          )
        else // si ya hay fotos: se pueden abrir y borrar
          MediaStrip(items: shots),
      ],
    );
  }
}
