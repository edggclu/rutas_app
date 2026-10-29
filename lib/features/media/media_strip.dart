import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/toast.dart';
import '../../domain/media_rules.dart';
import '../../domain/models/media_item.dart';
import '../../providers/actions_provider.dart';
import 'confirm_delete.dart';
import 'media_viewer_screen.dart';

const _size = 84.0; // lado de cada miniatura

/// Tira horizontal de miniaturas de fotos y videos. Tocar una la abre a pantalla completa
/// y la X de la esquina la borra (si todavía no se ha subido). Si no hay archivos, no dibuja nada.
class MediaStrip extends ConsumerWidget {
  const MediaStrip({super.key, required this.items, this.deletable = true});

  final List<MediaItem> items;
  final bool deletable; // false en una visita ya cerrada: solo se puede ver

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: _size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _Tile(
          item: items[i],
          deletable: deletable,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => MediaViewerScreen(items: items, initialIndex: i, deletable: deletable)),
          ),
          onDelete: () async {
            final messenger = ScaffoldMessenger.of(context); // se guardan antes del await
            final actions = ref.read(mediaActionsProvider);
            if (!await confirmDeleteMedia(context, items[i])) return; // canceló
            try {
              await actions.delete(items[i]);
              messenger.toast(items[i].kind.isVideo ? 'Video borrado' : 'Foto borrada');
            } catch (_) {
              messenger.toast('No se pudo borrar. Intenta de nuevo.');
            }
          },
        ),
      ),
    );
  }
}

/// Una miniatura con su estado de envío (reloj o nube) y, si se puede, la X para borrarla.
class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.deletable, required this.onOpen, required this.onDelete});

  final MediaItem item;
  final bool deletable;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final sent = item.sent;
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onOpen,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.kind.isVideo
                    ? Container( // sin miniatura del video: un cuadro oscuro con el ícono de reproducir
                        color: AppColors.navy900,
                        child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 36)),
                      )
                    : Image.file(
                        File(item.localPath),
                        fit: BoxFit.cover,
                        cacheWidth: 168, // decodifica pequeño para ahorrar memoria
                        errorBuilder: (context, error, stack) => Container(
                          color: AppColors.gris100,
                          child: const Icon(Icons.broken_image, color: AppColors.gris400),
                        ),
                      ),
              ),
            ),
          ),
          Positioned( // reloj (pendiente de subir) o nube (enviada)
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: sent ? AppColors.ok : AppColors.alerta, shape: BoxShape.circle),
              child: Icon(sent ? Icons.cloud_done : Icons.schedule, size: 14, color: Colors.white),
            ),
          ),
          if (deletable && canDeleteMedia(item)) // lo ya subido no se puede quitar
            Positioned(
              left: 2,
              top: 2,
              child: GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: Padding( // zona de toque más grande que el círculo
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
