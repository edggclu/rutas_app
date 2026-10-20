import 'dart:io'; // File: para mostrar las fotos guardadas en el teléfono

import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget
import 'package:telyser_app/domain/models/media_item.dart';
import 'package:telyser_app/providers/route_providers.dart';

import '../../../core/theme/app_colors.dart'; // colores
import '../../../core/widgets/toast.dart'; // avisos cortos
import '../capture_photo.dart'; // capturePhoto

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
      ],
    );
  }
}

/// Miniatura de una foto con un indicador: reloj (pendiente de subir) o nube (enviada).
class _Thumb extends StatelessWidget { // widget sin estado propio
  const _Thumb({required this.photo}); // recibe la fila de la foto

  final MediaItem photo; // la foto guardada

  @override
  Widget build(BuildContext context) { // dibuja la miniatura
    final sent = photo.sent; // ¿ya se subió al servidor?
    return Stack( // apila la imagen y el indicador
      children: [
        ClipRRect( // recorta con esquinas redondeadas
          borderRadius: BorderRadius.circular(8), // radio de las esquinas
          child: Image.file( // muestra el archivo guardado en el teléfono
            File(photo.localPath), // la ruta de la foto
            width: 84, // ancho
            height: 84, // alto
            fit: BoxFit.cover, // llena el cuadro recortando lo que sobre
            cacheWidth: 168, // decodifica a tamaño pequeño para ahorrar memoria
            errorBuilder: (context, error, stack) => Container( // si el archivo no se puede leer
              width: 84, // ancho
              height: 84, // alto
              color: AppColors.gris100, // fondo gris claro
              child: const Icon(Icons.broken_image, color: AppColors.gris400), // ícono de imagen rota
            ),
          ),
        ),
        Positioned( // coloca el indicador en la esquina
          right: 4, // pegado a la derecha
          bottom: 4, // pegado abajo
          child: Container( // círculo de color
            padding: const EdgeInsets.all(3), // margen interno
            decoration: BoxDecoration( // estilo
              color: sent ? AppColors.ok : AppColors.alerta, // verde si se subió, ámbar si está pendiente
              shape: BoxShape.circle, // forma circular
            ),
            child: Icon( // el ícono
              sent ? Icons.cloud_done : Icons.schedule, // nube si se subió, reloj si falta
              size: 14, // tamaño
              color: Colors.white, // blanco
            ),
          ),
        ),
      ],
    );
  }
}