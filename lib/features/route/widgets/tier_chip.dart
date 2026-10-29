import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../domain/models/enums.dart';

/// El color de cada tipo de cliente: A es el más importante.
Color tierColor(ClientTier? tier) => switch (tier) {
      ClientTier.a => AppColors.rojo,
      ClientTier.b => AppColors.alerta,
      ClientTier.c => AppColors.info,
      null => AppColors.gris400,
    };

/// "Cliente A", "Cliente B" o "Cliente C". Si el servidor no manda el tipo, no dibuja nada.
class TierChip extends StatelessWidget {
  const TierChip(this.tier, {super.key});

  final ClientTier? tier;

  @override
  Widget build(BuildContext context) {
    final t = tier;
    if (t == null) return const SizedBox.shrink();
    return TagChip(label: 'Cliente ${t.code}', background: tierColor(t).withValues(alpha: 0.14), foreground: tierColor(t));
  }
}
