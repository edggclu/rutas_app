import 'package:flutter/material.dart'; // widgets básicos

import '../theme/app_colors.dart'; // colores

/// Botón que se confirma deslizando (evita toques accidentales con el teléfono
/// en la bolsa). La parte ya deslizada se pone blanca con borde del color del botón.
/// El deshacer lo maneja quien recibe onConfirmed: showUndoBar y la cola.
class SlideToConfirm extends StatefulWidget { // widget con estado: guarda cuánto se ha deslizado
  const SlideToConfirm({ // constructor
    super.key, // llave de Flutter
    required this.label, // texto del botón
    required this.onConfirmed, // qué hacer al completar el deslizamiento
    this.color = AppColors.rojo, // color del botón y de su borde
    this.enabled = true, // false = gris y sin respuesta
    this.height = 60, // alto del botón
  });

  final String label; // texto
  final VoidCallback onConfirmed; // función al completar
  final Color color; // color
  final bool enabled; // ¿está activo?
  final double height; // alto

  @override
  State<SlideToConfirm> createState() => SlideToConfirmState(); // crea el estado
}

class SlideToConfirmState extends State<SlideToConfirm> { // el estado del deslizable
  double _dx = 0; // cuánto se ha movido el círculo (0 = al inicio)
  bool _confirmed = false; // true una vez completado (evita confirmar dos veces)

  /// Regresa el control a su posición inicial (por ejemplo, al deshacer o cancelar).
  void reset() => setState(() { // redibuja
        _dx = 0; // el círculo vuelve al inicio
        _confirmed = false; // se puede volver a deslizar
      });

  @override
  Widget build(BuildContext context) { // dibuja el botón
    final h = widget.height; // alto
    final thumb = h - 8; // diámetro del círculo (deja 4 de margen arriba y abajo)
    return LayoutBuilder(builder: (context, c) { // permite saber el ancho disponible
      final full = c.maxWidth; // ancho total del botón
      final maxDx = (full - thumb - 8).clamp(0.0, double.infinity).toDouble(); // lo máximo que puede avanzar el círculo
      final active = widget.enabled && !_confirmed; // ¿responde al dedo?
      final base = widget.enabled ? widget.color : AppColors.gris100; // color de la pista
      final accent = widget.enabled ? widget.color : AppColors.gris400; // color del círculo, su borde y el texto sobre blanco

      /// El texto centrado (a la derecha del círculo). Se dibuja dos veces: blanco sobre la
      /// pista y de color sobre la parte blanca.
      Widget label(Color textColor) => Center( // centrado
            child: Padding( // deja libre el lugar del círculo
              padding: EdgeInsets.only(left: thumb), // margen izquierdo
              child: Text( // el texto
                widget.label, // texto del botón
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15), // estilo
              ),
            ),
          );

      return GestureDetector( // detecta el arrastre
        onHorizontalDragUpdate: active // mientras arrastra
            ? (d) => setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, maxDx).toDouble()) // mueve el círculo sin salirse
            : null, // inactivo: no responde
        onHorizontalDragEnd: active // al soltar
            ? (_) {
                if (maxDx > 0 && _dx >= maxDx * 0.9) { // llegó casi hasta el final
                  setState(() { // lo deja completo
                    _dx = maxDx; // al final
                    _confirmed = true; // ya confirmado
                  });
                  widget.onConfirmed(); // avisa a quien lo usa
                } else { // no llegó
                  setState(() => _dx = 0); // regresa al inicio
                }
              }
            : null, // inactivo: no responde
        child: SizedBox( // fija el alto
          height: h, // alto
          child: Stack( // apila pista, parte deslizada y círculo
            children: [
              Positioned.fill( // 1) la pista, de todo el ancho
                child: Container( // caja de color
                  decoration: BoxDecoration( // estilo
                    color: base, // color de la pista
                    borderRadius: BorderRadius.circular(h / 2), // extremos redondos
                  ),
                  child: label(widget.enabled ? Colors.white : AppColors.gris400), // texto blanco (gris si está inactivo)
                ),
              ),
              if (widget.enabled && _dx > 0) // 2) la parte ya deslizada, solo mientras hay avance
                Positioned( // pegada a la izquierda
                  left: 0, // desde el borde izquierdo
                  top: 0, // altura completa
                  bottom: 0, // altura completa
                  width: _dx + thumb + 8, // crece junto con el círculo (hasta cubrir todo)
                  child: Container( // píldora blanca con borde de color
                    decoration: BoxDecoration( // estilo
                      color: Colors.white, // fondo blanco
                      borderRadius: BorderRadius.circular(h / 2), // extremos redondos
                      border: Border.all(color: widget.color, width: 2), // borde del color del botón
                    ),
                    child: ClipRRect( // recorta el texto a la forma de la píldora
                      borderRadius: BorderRadius.circular(h / 2 - 2), // un poco menos por el borde
                      child: OverflowBox( // deja que el texto mida lo mismo que en la pista
                        alignment: Alignment.centerLeft, // pegado a la izquierda
                        minWidth: full, // mismo ancho que el botón completo
                        maxWidth: full, // mismo ancho que el botón completo
                        child: label(widget.color), // texto del color del botón sobre el blanco
                      ),
                    ),
                  ),
                ),
              Positioned( // 3) el círculo que se desliza
                left: 4 + _dx, // posición actual
                top: 4, // margen superior
                child: Container( // el círculo
                  width: thumb, // diámetro
                  height: thumb, // diámetro
                  decoration: BoxDecoration( // estilo
                    color: Colors.white, // fondo blanco
                    shape: BoxShape.circle, // redondo
                    border: Border.all(color: accent, width: 2), // anillo del color (se ve sobre la parte blanca)
                  ),
                  child: Icon(Icons.keyboard_double_arrow_right, color: accent), // las flechas
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}