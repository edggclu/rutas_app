import 'package:flutter/material.dart'; // widgets básicos

import '../theme/app_colors.dart'; // colores

/// Una imagen que puede ser un asset (datos de prueba) o una URL (API real).
/// Si no carga, muestra un ícono de imagen rota.
class AppImage extends StatelessWidget {
  const AppImage({super.key, required this.src, this.fit = BoxFit.cover});

  final String src; // ruta del asset o URL
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final broken = Container(
      color: AppColors.gris100,
      child: const Center(child: Icon(Icons.broken_image, color: AppColors.gris400)),
    );
    if (src.startsWith('http')) {
      return Image.network(src, fit: fit, errorBuilder: (context, error, stack) => broken); // necesita señal
    }
    return Image.asset(src, fit: fit, errorBuilder: (context, error, stack) => broken);
  }
}