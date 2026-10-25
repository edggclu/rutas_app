import 'package:flutter/material.dart';
import 'package:telyser_app/core/widgets/app_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/models.dart';

const kPinSize = 30.0; // diámetro de cada pin en pantalla

/// El croquis con sus pines. Al tocar un pin (o su chip) se muestra su nota.
class SketchView extends StatefulWidget { // con estado: recuerda qué pin está elegido
  const SketchView({super.key, required this.sketch}); // recibe el croquis

  final Sketch sketch; // el croquis

  @override
  State<SketchView> createState() => _SketchViewState(); // crea el estado
}

class _SketchViewState extends State<SketchView> { // el estado del croquis
  int? _selectedId; // id del pin elegido (null = ninguno)

  SketchPin? get _selected { // el pin elegido, o null
    for (final p in widget.sketch.pins) { // recorre los pines
      if (p.id == _selectedId) return p; // el que coincide
    }
    return null; // ninguno elegido
  }

  @override
  Widget build(BuildContext context) { // dibuja el croquis
    final sketch = widget.sketch; // atajo al croquis
    final selected = _selected; // el pin elegido
    return Column( // elementos uno debajo de otro
      crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
      children: [
        const Text( // título
          'Croquis', // texto
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700), // negritas
        ),
        const SizedBox(height: 8), // espacio vertical
        Container( // marco de la imagen
          clipBehavior: Clip.antiAlias, // recorta la imagen con las esquinas redondeadas
          decoration: BoxDecoration( // estilo
            borderRadius: BorderRadius.circular(12), // esquinas redondeadas
            border: Border.all(color: AppColors.gris200), // borde gris claro
          ),
          child: AspectRatio( // fija la proporción de la imagen
            aspectRatio: sketch.aspectRatio, // ancho / alto
            child: LayoutBuilder( // permite saber el tamaño real para colocar los pines
              builder: (context, c) { // c = espacio disponible
                final w = c.maxWidth; // ancho de la imagen en pantalla
                final h = c.maxHeight; // alto de la imagen en pantalla
                return Stack( // apila la imagen y los pines
                  children: [
                    Positioned.fill(child: AppImage(src: sketch.image, fit: BoxFit.fill,)), // la imagen de fondo
                    for (final p in sketch.pins) // un pin por cada punto
                      Positioned( // lo coloca en su posición relativa
                        left: p.x.clamp(0.0, 1.0).toDouble() * w - kPinSize / 2, // centra el pin en x
                        top: p.y.clamp(0.0, 1.0).toDouble() * h - kPinSize / 2, // centra el pin en y
                        child: PinDot( // el círculo numerado
                          label: p.label, // texto del pin
                          selected: p.id == _selectedId, // ¿es el elegido?
                          onTap: () => setState(() => _selectedId = p.id), // al tocarlo, lo elige
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10), // espacio vertical
        Wrap( // un chip por pin (más fáciles de tocar que los pines)
          spacing: 8, // espacio horizontal
          runSpacing: 8, // espacio vertical
          children: [
            for (final p in sketch.pins) // por cada pin
              ChoiceChip( // chip elegible
                label: Text(p.label), // texto
                selected: p.id == _selectedId, // ¿es el elegido?
                onSelected: (_) => setState(() => _selectedId = p.id), // al tocarlo, lo elige
              ),
          ],
        ),
        const SizedBox(height: 10), // espacio vertical
        AppCard( // la nota del pin elegido
          child: selected == null // si no hay pin elegido
              ? const Text( // pista
                  'Toca un punto para ver su nota.', // texto
                  style: TextStyle(color: AppColors.gris600), // gris
                )
              : Column( // si hay pin elegido
                  crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
                  children: [
                    Text( // etiqueta del pin
                      selected.label, // ej. "C3"
                      style: const TextStyle(fontWeight: FontWeight.w700), // negritas
                    ),
                    const SizedBox(height: 2), // espacio vertical
                    Text(selected.note ?? 'Sin nota.'), // la nota del ingeniero
                  ],
                ),
        ),
      ],
    );
  }
}

/// El círculo numerado de un pin (lo usan el croquis de lectura y el editor).
class PinDot extends StatelessWidget { // widget sin estado propio
  const PinDot({super.key, required this.label, required this.selected, required this.onTap}); // constructor

  final String label; // texto
  final bool selected; // ¿está elegido?
  final VoidCallback onTap; // qué hacer al tocar

  @override
  Widget build(BuildContext context) { // dibuja el pin
    return GestureDetector( // detecta el toque
      onTap: onTap, // al tocar
      child: Container( // el círculo
        width: kPinSize, // diámetro
        height: kPinSize, // diámetro
        alignment: Alignment.center, // texto al centro
        decoration: BoxDecoration( // estilo
          color: selected ? AppColors.navy900 : AppColors.rojo, // navy si está elegido, rojo si no
          shape: BoxShape.circle, // redondo
          border: Border.all(color: Colors.white, width: 2), // anillo blanco para que se vea sobre el dibujo
        ),
        child: FittedBox( // encoge el texto si no cabe (por ejemplo "NVR")
          child: Padding( // margen interno
            padding: const EdgeInsets.all(3), // 3 por cada lado
            child: Text( // el texto
              label, // ej. "C1"
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12), // blanco y en negritas
            ),
          ),
        ),
      ),
    );
  }
}

