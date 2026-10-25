import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// La caja blanca con borde y esquinas redondeadas que usan casi todas las pantallas.
class AppCard extends StatelessWidget { // widget sin estado propio
  const AppCard({ // constructor
    super.key, // llave de Flutter
    required this.child, // lo que va adentro
    this.padding = const EdgeInsets.all(14), // margen interno (14 por defecto)
  });

  final Widget child; // contenido
  final EdgeInsets padding; // margen interno

  @override
  Widget build(BuildContext context) { // dibuja la tarjeta
    return Container( // la caja
      width: double.infinity, // todo el ancho
      padding: padding, // margen interno
      decoration: BoxDecoration( // estilo
        color: Colors.white, // fondo blanco
        borderRadius: BorderRadius.circular(12), // esquinas redondeadas
        border: Border.all(color: AppColors.gris200), // borde gris claro
      ),
      child: child, // el contenido
    );
  }
}