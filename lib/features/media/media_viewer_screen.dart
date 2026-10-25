import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/toast.dart';
import '../../domain/media_rules.dart';
import '../../domain/models/media_item.dart';
import '../../providers/actions_provider.dart';
import 'confirm_delete.dart';

/// Visor a pantalla completa de las fotos y videos de una tira. Se desliza de lado entre ellos,
/// las fotos se acercan con dos dedos y los videos se reproducen. Desde aquí también se borra.
class MediaViewerScreen extends ConsumerStatefulWidget {
  const MediaViewerScreen({super.key, required this.items, this.initialIndex = 0});

  final List<MediaItem> items; // los archivos de la tira, tal como estaban al abrir
  final int initialIndex;

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  late List<MediaItem> _items = List.of(widget.items); // se va achicando al borrar
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final item = _items[_index];
    final messenger = ScaffoldMessenger.of(context); // se guardan antes del await
    final navigator = Navigator.of(context);
    final actions = ref.read(mediaActionsProvider);
    if (!await confirmDeleteMedia(context, item) || !mounted) return; // canceló
    setState(() => _busy = true);
    try {
      await actions.delete(item);
      if (!mounted) return;
      if (_items.length == 1) { // era el último: no queda nada que ver
        navigator.pop();
      } else {
        setState(() {
          _items = [for (final m in _items) if (m.id != item.id) m];
          _index = _index.clamp(0, _items.length - 1);
          _busy = false;
        });
      }
      messenger.toast(item.kind.isVideo ? 'Video borrado' : 'Foto borrada');
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.toast('No se pudo borrar. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final current = _items[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} de ${_items.length}', style: const TextStyle(fontSize: 16)),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: _items.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => _items[i].kind.isVideo
            ? _VideoPage(key: ValueKey(_items[i].id), path: _items[i].localPath)
            : InteractiveViewer( // pellizcar para acercar
                maxScale: 5,
                child: Center(
                  child: Image.file(
                    File(_items[i].localPath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.broken_image, color: AppColors.gris400, size: 64),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottom),
        child: canDeleteMedia(current)
            ? OutlinedButton.icon(
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(current.kind.isVideo ? 'Borrar video' : 'Borrar foto'),
              )
            : const Text( // ya está en el servidor: la app no la puede quitar
                'Ya se subió al servidor y no se puede borrar desde la app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gris400, fontSize: 13),
              ),
      ),
    );
  }
}

/// Reproductor de un video guardado en el teléfono. Toca para pausar o reanudar.
class _VideoPage extends StatefulWidget {
  const _VideoPage({super.key, required this.path});

  final String path;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late final VideoPlayerController _ctrl = VideoPlayerController.file(File(widget.path));
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ctrl.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _ctrl.setLooping(true);
      _ctrl.play(); // arranca solo al abrirlo
    }).catchError((_) {
      if (mounted) setState(() => _failed = true); // archivo dañado o formato que el teléfono no abre
    });
  }

  @override
  void dispose() {
    _ctrl.dispose(); // libera el decodificador
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Text('No se pudo reproducir el video.', style: TextStyle(color: Colors.white70)),
      );
    }
    if (!_ctrl.value.isInitialized) return const Center(child: CircularProgressIndicator());
    return GestureDetector(
      onTap: () => setState(() => _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play()),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(aspectRatio: _ctrl.value.aspectRatio, child: VideoPlayer(_ctrl)),
          ),
          if (!_ctrl.value.isPlaying) // en pausa se muestra el botón de reproducir
            const Icon(Icons.play_circle_fill, color: Colors.white70, size: 72),
        ],
      ),
    );
  }
}
