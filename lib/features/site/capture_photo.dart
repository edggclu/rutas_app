import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telyser_app/data/providers.dart';

/// Abre la cámara y guarda la foto en el teléfono. Devuelve false si el técnico canceló.
Future<bool> capturePhoto( // toma y guarda una foto
  WidgetRef ref, { // para leer el repositorio de fotos
  required int visitId, // visita a la que pertenece
  String kind = 'progress', // tipo: avance, solicitud, garantía...
}) async {
  final shot = await ImagePicker().pickImage( // abre la cámara y espera la foto
    source: ImageSource.camera, // usar la cámara
    maxWidth: 1600, // reduce el ancho máximo para que pese poco
    imageQuality: 70, // calidad JPEG
  );
  if (shot == null) return false; // el técnico canceló: no se guarda nada
  await ref.read(mediaRepositoryProvider).addPhoto( // copia la foto y la deja pendiente de subir
      visitId: visitId, sourcePath: shot.path, kind: kind); // con su visita y su tipo
  return true; // se guardó
}