import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telyser_app/providers/infra_providers.dart';

import '../../domain/models/media_item.dart';

/// Abre la cámara y guarda la foto en el teléfono. Devuelve el id de la foto, o null si el técnico canceló.
Future<String?> capturePhoto( // toma y guarda una foto
  WidgetRef ref, { // para leer el repositorio
  required int visitId, // visita a la que pertenece
  MediaKind kind = MediaKind.progress, // tipo de foto
}) async {
  final shot = await ImagePicker().pickImage( // abre la cámara y espera la foto
    source: ImageSource.camera, // usar la cámara
    maxWidth: 1600, // reduce el ancho máximo para que pese poco
    imageQuality: 70, // calidad JPEG
  );
  if (shot == null) return null; // el técnico canceló: no se guarda nada
  return ref.read(mediaRepositoryProvider).addPhoto( // copia la foto y la deja pendiente de subir
      visitId: visitId, sourcePath: shot.path, kind: kind); // con su visita y su tipo
}

/// Abre la cámara de video y guarda el clip. Devuelve su id, o null si se canceló. [maxSeconds] sale de los parámetros (`video_max_s`).
Future<String?> captureVideo( // graba y guarda un video
  WidgetRef ref, { // para leer el repositorio
  required int visitId, // visita a la que pertenece
  required int maxSeconds, // duración máxima permitida
  MediaKind kind = MediaKind.cablingVideo, // tipo: video del cableado
}) async {
  final clip = await ImagePicker().pickVideo( // abre la cámara en modo video
    source: ImageSource.camera, // usar la cámara
    maxDuration: Duration(seconds: maxSeconds), // la grabación se corta al llegar al máximo
  );
  if (clip == null) return null; // el técnico canceló
  return ref.read(mediaRepositoryProvider).addVideo( // copia el video y lo deja pendiente de subir
      visitId: visitId, sourcePath: clip.path, kind: kind); // con su visita y su tipo
}