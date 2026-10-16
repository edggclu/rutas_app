import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Botón que se confirma deslizando (evita toques accidentales con el teléfono
/// en la bolsa). El deshacer lo maneja quien recibe onConfirmed: showUndoBar y la cola
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.color = AppColors.rojo,
    this.enabled = true,
    this.height = 60,
  });

  final String label;
  final VoidCallback onConfirmed;
  final Color color;
  final bool enabled;
  final double height;

  @override
  State<SlideToConfirm> createState() => SlideToConfirmState();
}

class SlideToConfirmState extends State<SlideToConfirm> {
  double _dx = 0;
  bool _confirmed = false;

  /// Regresa el control a su posición inicial (por ejemplo, al deshacer).
  void reset() => setState(() {
        _dx = 0;
        _confirmed = false;
      });

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final thumb = h - 8;
    return LayoutBuilder(builder: (context, c) {
      final maxDx = (c.maxWidth - thumb - 8).clamp(0.0, double.infinity).toDouble();
      final active = widget.enabled && !_confirmed;
      return GestureDetector(
        onHorizontalDragUpdate: active
            ? (d) => setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, maxDx).toDouble())
            : null,
        onHorizontalDragEnd: active
            ? (_) {
                if (maxDx > 0 && _dx >= maxDx * 0.9) {
                  setState(() {
                    _dx = maxDx;
                    _confirmed = true;
                  });
                  widget.onConfirmed();
                } else {
                  setState(() => _dx = 0);
                }
              }
            : null,
        child: Container(
          height: h,
          decoration: BoxDecoration(
            color: widget.enabled ? widget.color : AppColors.gris100,
            borderRadius: BorderRadius.circular(h / 2),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(left: thumb),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.enabled ? Colors.white : AppColors.gris400,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 4 + _dx,
                top: 4,
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.keyboard_double_arrow_right,
                    color: widget.enabled ? widget.color : AppColors.gris400,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
