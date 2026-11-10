import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/time/time_utils.dart';
import '../../../domain/dispatch_rules.dart';

/// Elegir el día: Hoy, Mañana u otra fecha (abre el calendario, hasta 90 días adelante).
class DayChoice extends StatelessWidget {
  const DayChoice({super.key, required this.value, required this.today, required this.onChanged});

  final DateTime value;
  final DateTime today; // el día de hoy, solo la fecha
  final ValueChanged<DateTime> onChanged;

  Future<void> _pickOther(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      locale: const Locale('es', 'MX'),
    );
    if (picked != null) onChanged(dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = today.add(const Duration(days: 1));
    final day = dateOnly(value);
    final isOther = day != today && day != tomorrow;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Día', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gris600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(label: const Text('Hoy'), selected: day == today, onSelected: (_) => onChanged(today)),
              ChoiceChip(label: const Text('Mañana'), selected: day == tomorrow, onSelected: (_) => onChanged(tomorrow)),
              ChoiceChip(
                avatar: const Icon(Icons.calendar_month, size: 18),
                label: Text(isOther ? formatLongDate(day) : 'Otra fecha'),
                selected: isOther,
                onSelected: (_) => _pickOther(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
