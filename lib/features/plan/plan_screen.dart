import 'package:flutter/material.dart'; // widgets básicos
import 'package:telyser_app/features/plan/widgets/sketch_view.dart';

import '../../core/theme/app_colors.dart'; // colores
import '../../core/widgets/app_card.dart'; // la tarjeta compartida
import '../../core/widgets/app_header.dart'; // encabezado navy
import '../../domain/models/models.dart'; // Job y ChecklistItem

/// D1 · Plan del trabajo (solo lectura): notas, material, herramienta y croquis.
class PlanScreen extends StatelessWidget { // widget sin estado propio
  const PlanScreen({super.key, required this.job}); // recibe el trabajo

  final Job job; // el trabajo

  @override
  Widget build(BuildContext context) { // dibuja la pantalla
    final plan = job.plan; // el plan (puede ser null)
    return Scaffold( // estructura de la pantalla
      body: Column( // elementos uno debajo de otro
        children: [
          AppHeader( // encabezado navy
            subtitle: job.folio, // arriba: el folio
            title: 'Plan del trabajo', // título
            onBack: () => Navigator.of(context).pop(), // flecha para regresar
          ),
          Expanded( // ocupa el espacio que queda
            child: plan == null // si el trabajo no tiene plan
                ? const Center( // mensaje centrado
                    child: Padding( // margen alrededor
                      padding: EdgeInsets.all(32), // 32 por cada lado
                      child: Text( // texto
                        'Este trabajo todavía no tiene plan.', // mensaje
                        textAlign: TextAlign.center, // centrado
                        style: TextStyle(color: AppColors.gris600), // gris
                      ),
                    ),
                  )
                : ListView( // contenido que se puede desplazar
                    padding: const EdgeInsets.all(16), // margen de 16
                    children: [
                      if (plan.notes != null) ...[ // si hay notas
                        AppCard( // la caja compartida
                          child: Column( // título y texto
                            crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
                            children: [
                              const Text( // título
                                'Notas del ingeniero', // texto
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gris600), // pequeño y gris
                              ),
                              const SizedBox(height: 4), // espacio vertical
                              Text(plan.notes!), // las notas
                            ],
                          ),
                        ),
                        const SizedBox(height: 12), // espacio vertical
                      ],
                      if (plan.materials.isNotEmpty) ...[ // si hay material
                        _ItemsCard(title: 'Material', items: plan.materials), // la lista de material
                        const SizedBox(height: 12), // espacio vertical
                      ],
                      if (plan.tools.isNotEmpty) ...[ // si hay herramienta
                        _ItemsCard(title: 'Herramienta', items: plan.tools), // la lista de herramienta
                        const SizedBox(height: 12), // espacio vertical
                      ],
                      if (plan.sketch != null) SketchView(sketch: plan.sketch!), // el croquis con pines, si hay
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Una lista de renglones con su cantidad.
class _ItemsCard extends StatelessWidget { // widget sin estado propio
  const _ItemsCard({required this.title, required this.items}); // constructor

  final String title; // título de la lista
  final List<ChecklistItem> items; // los renglones

  @override
  Widget build(BuildContext context) { // dibuja la tarjeta
    return AppCard( // la caja compartida
      child: Column( // elementos uno debajo de otro
        crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
        children: [
          Text( // título
            title, // texto
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gris600), // pequeño y gris
          ),
          const SizedBox(height: 6), // espacio vertical
          for (final i in items) // por cada renglón
            Padding( // margen vertical
              padding: const EdgeInsets.symmetric(vertical: 3), // 3 arriba y abajo
              child: Row( // nombre a la izquierda, cantidad a la derecha
                children: [
                  Expanded(child: Text(i.text)), // nombre del material
                  Text( // cantidad
                    i.quantityLabel, // ej. "x8" (vacío si no hay cantidad)
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.gris600), // gris
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}