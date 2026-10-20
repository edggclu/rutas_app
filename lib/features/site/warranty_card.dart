import 'package:flutter/material.dart'; // widgets básicos

import '../../core/theme/app_colors.dart'; // colores

/// Tarjeta de En sitio que muestra si la garantía ya se documentó.
class WarrantyCard extends StatelessWidget { // widget sin estado propio
  const WarrantyCard({ // constructor
    super.key, // llave de Flutter
    required this.documented, // ¿ya se documentó?
    required this.onOpen, // qué hacer al tocar el botón
    this.causeLabel, // causa documentada, para mostrarla
  });

  final bool documented; // true = ya está documentada
  final String? causeLabel; // ej. "Humedad o salitre"
  final VoidCallback onOpen; // abre la pantalla de garantía

  @override
  Widget build(BuildContext context) { // dibuja la tarjeta
    return Container( // caja de color
      width: double.infinity, // todo el ancho
      padding: const EdgeInsets.all(14), // margen interno
      decoration: BoxDecoration( // estilo
        color: documented ? AppColors.okSuave : AppColors.alertaSuave, // verde si está lista, ámbar si falta
        borderRadius: BorderRadius.circular(12), // esquinas redondeadas
      ),
      child: Column( // textos y botón
        crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
        children: [
          Text( // título
            documented ? 'Garantía documentada' : 'Garantía pendiente', // según el estado
            style: TextStyle( // estilo
              fontWeight: FontWeight.w700, // negritas
              color: documented ? AppColors.ok : AppColors.alerta, // verde o ámbar
            ),
          ),
          const SizedBox(height: 4), // espacio vertical
          Text( // explicación
            documented
                ? 'Causa: ${causeLabel ?? '—'}' // la causa guardada
                : 'Documenta la causa, la foto de la falla y el número de serie antes de terminar.', // lo que falta
            style: const TextStyle(color: AppColors.gris900, fontSize: 13), // texto oscuro y pequeño
          ),
          const SizedBox(height: 10), // espacio vertical
          FilledButton( // botón
            onPressed: onOpen, // abre la pantalla de garantía
            child: Text(documented ? 'Ver o editar garantía' : 'Documentar garantía'), // texto según el estado
          ),
        ],
      ),
    );
  }
}