import 'package:flutter/material.dart'; // widgets básicos

import '../../../core/theme/app_colors.dart'; // colores
import '../../../core/widgets/app_card.dart'; // la tarjeta compartida
import '../../../domain/models/models.dart'; // Job
import '../../plan/plan_screen.dart'; // la pantalla del plan

/// "Qué hay que hacer": descripción del trabajo y resumen del plan.
class TaskCard extends StatelessWidget { // widget sin estado propio
  const TaskCard({super.key, required this.job}); // recibe el trabajo

  final Job job; // el trabajo

  @override
  Widget build(BuildContext context) { // dibuja la tarjeta
    final summary = job.planSummary; // resumen del plan (null si no hay)
    return AppCard( // la caja compartida
      child: Column( // elementos uno debajo de otro
        crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
        children: [
          const Text( // título
            'Qué hay que hacer', // texto
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gris600), // pequeño y gris
          ),
          const SizedBox(height: 4), // espacio vertical
          Text(job.description), // descripción del trabajo
          if (summary != null) ...[ // si hay resumen del plan
            const SizedBox(height: 4), // espacio vertical
            Text(summary), // el resumen
          ],
          if (job.plan != null) ...[ // si el ingeniero dejó un plan completo
            const SizedBox(height: 6), // espacio vertical
            GestureDetector( // enlace tocable
              onTap: () => Navigator.of(context).push( // abre la pantalla del plan
                MaterialPageRoute<void>(
                  builder: (_) => PlanScreen(job: job), // con este trabajo
                ),
              ),
              child: const Text( // texto del enlace
                'Ver plan completo ›', // texto
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.rojo), // rojo
              ),
            ),
          ],
        ],
      ),
    );
  }
}