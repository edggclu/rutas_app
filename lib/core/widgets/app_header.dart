import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Encabezado navy. Si [onBack] no es nulo, el botón "‹" va antes del título
/// (por ejemplo: "‹ Salida", "‹ Hotel Bahía").
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: AppColors.navy900,
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null || trailing != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (subtitle != null)
                  Flexible(
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.gris400,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          if (subtitle != null) const SizedBox(height: 4),
          Row(
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 6, top: 2, bottom: 2),
                    child: Icon(Icons.chevron_left, color: Colors.white, size: 34),
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 8), bottom!],
        ],
      ),
    );
  }
}
