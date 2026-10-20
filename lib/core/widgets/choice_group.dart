import 'package:flutter/material.dart'; // widgets básicos

import '../theme/app_colors.dart'; // colores

/// Un grupo de opciones tipo chip: una sola elegida a la vez.
class ChoiceGroup<T> extends StatelessWidget { // T = tipo del valor (enum o bool)
  const ChoiceGroup({ // constructor
    super.key, // llave de Flutter
    required this.title, // título del grupo
    required this.options, // lista de (valor, texto)
    required this.selected, // el valor elegido (null = ninguno)
    required this.onSelected, // qué hacer al elegir
    this.disabled = const {}, // valores que no se pueden elegir
  });

  final String title; // título
  final List<(T, String)> options; // opciones: pares (valor, texto)
  final T? selected; // el valor elegido
  final ValueChanged<T> onSelected; // función al elegir
  final Set<T> disabled; // valores bloqueados

  @override
  Widget build(BuildContext context) { // dibuja el grupo
    return Padding( // margen abajo
      padding: const EdgeInsets.only(bottom: 12), // 12 de margen inferior
      child: Column( // título y chips
        crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
        children: [
          Text( // título
            title, // texto
            style: const TextStyle( // estilo
              fontSize: 13, // tamaño
              fontWeight: FontWeight.w700, // negritas
              color: AppColors.gris600, // gris
            ),
          ),
          const SizedBox(height: 6), // espacio vertical
          Wrap( // chips en fila, que bajan de renglón si no caben
            spacing: 8, // espacio horizontal
            runSpacing: 8, // espacio vertical
            children: [
              for (final (value, label) in options) // por cada opción
                ChoiceChip( // chip elegible
                  label: Text(label), // texto
                  selected: selected == value, // ¿es la elegida?
                  onSelected: disabled.contains(value) // si está bloqueada
                      ? null // no responde
                      : (_) => onSelected(value), // si no, avisa cuál se eligió
                ),
            ],
          ),
        ],
      ),
    );
  }
}