import 'package:flutter/material.dart'; // widgets básicos

import '../../../core/theme/app_colors.dart'; // colores
import '../../../core/widgets/app_image.dart'; // la imagen del croquis
import '../../../domain/models/models.dart'; // Sketch y SketchPin
import 'sketch_view.dart'; // PinDot y kPinSize

/// El croquis en modo edición: tocar un lugar vacío agrega un pin, tocar un pin lo elige
/// y arrastrarlo lo mueve. No guarda nada: avisa con los callbacks.
class SketchEditor extends StatelessWidget {
  const SketchEditor({
    super.key,
    required this.sketch,
    required this.selectedId,
    required this.onAdd,
    required this.onSelect,
    required this.onMove,
    required this.onDragLock,
  });

  final Sketch sketch;
  final int? selectedId;
  final void Function(double x, double y) onAdd; // posición relativa (0 a 1)
  final ValueChanged<int> onSelect;
  final void Function(int id, double dx, double dy) onMove; // cuánto se movió, en proporción a la imagen
  final ValueChanged<bool> onDragLock; // true mientras hay un dedo sobre un pin: la pantalla no debe desplazarse

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gris200),
      ),
      child: AspectRatio(
        aspectRatio: sketch.aspectRatio,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            return Stack(
              children: [
                Positioned.fill( // el fondo recibe el toque que agrega un pin
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => onAdd(
                      (d.localPosition.dx / w).clamp(0.0, 1.0),
                      (d.localPosition.dy / h).clamp(0.0, 1.0),
                    ),
                    child: AppImage(src: sketch.image, fit: BoxFit.fill),
                  ),
                ),
                for (final p in sketch.pins)
                  Positioned(
                    left: p.x.clamp(0.0, 1.0) * w - kPinSize / 2,
                    top: p.y.clamp(0.0, 1.0) * h - kPinSize / 2,
                    child: Listener( // no entra al duelo de gestos: la lista no le gana el arrastre
                      onPointerDown: (_) {
                        onDragLock(true); // la pantalla deja de desplazarse mientras se toca el pin
                        onSelect(p.id);
                      },
                      onPointerMove: (e) => onMove( // avisa del desplazamiento; la pantalla lo suma a la posición más reciente
                        p.id,
                        e.delta.dx / w,
                        e.delta.dy / h,
                      ),
                      onPointerUp: (_) => onDragLock(false),
                      onPointerCancel: (_) => onDragLock(false),
                      child: PinDot(label: p.label, selected: p.id == selectedId, onTap: () => onSelect(p.id)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
