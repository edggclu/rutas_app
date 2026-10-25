import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppTabItem {
  const AppTabItem(this.label, {this.badge = false});
  final String label;
  final bool badge; // true = punto rojo (hay algo sin leer)
}

/// Barra inferior navy; la pestaña activa va en rojo.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<AppTabItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.navy900,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: i == index ? AppColors.rojo : Colors.transparent,
                            border: i == index
                                ? null
                                : Border.all(color: AppColors.gris400, width: 2),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        if (items[i].badge && i != index) // el punto no se muestra en la pestaña abierta
                          Positioned(
                            right: -3,
                            top: -3,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.rojo,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.navy900, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                        color: i == index ? AppColors.rojo : AppColors.gris400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
