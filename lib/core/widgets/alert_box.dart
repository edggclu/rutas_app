import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Caja de aviso (saldo vencido, notas de acceso, guía de garantía…).
class AlertBox extends StatelessWidget {
  const AlertBox({
    super.key,
    required this.title,
    required this.body,
    this.background = AppColors.infoSuave,
    this.foreground = AppColors.info,
  });

  final String title;
  final String body;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(color: AppColors.gris900, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
