import 'package:flutter/material.dart';
import 'package:telyser_app/core/theme/app_colors.dart';
import 'package:telyser_app/core/time/time_utils.dart';
import 'package:telyser_app/core/widgets/tag_chip.dart';
import 'package:telyser_app/domain/models/models.dart';

/// Panel que aparece debajo de la tarjeta de visita cuando el tecnico marco 'Llegue' pregunta si ya te abrieron en la visita
/// widget sin estado propio, solo muestra datos
class ArrivalPanel extends StatelessWidget{

  final Visit visit; // la visita actual
  final VoidCallback onStart; // función que se ejecuta con "Empezar"
  final VoidCallback onNoAnswer; // función que se ejecuta con "No me abren"

  const ArrivalPanel ({
    super.key,
    required this.visit,
    required this.onStart,
    required this.onNoAnswer
  });


  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom; // alto de la barra de gestos del teléfono
    return Container(
      width: double.infinity, // todo el ancho de la pantalla
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 14, 16, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min, // la columna solo ocupa lo que necesita
        crossAxisAlignment: CrossAxisAlignment.start, // alineadoa  al izq
        children: [
          if (visit.arrivedAt != null)
            TagChip(
              label: "Llegue marcado ${formatClock(visit.arrivedAt!)}", // ej. "Llegué marcado 8:20"
              background: AppColors.okSuave, 
              foreground: AppColors.ok
            ),
            const SizedBox(height: 8,),
            Text(
              'Llegaste a ${visit.place.name}', // Titulo con el nombre del lugar
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), // bold
            ),
            const Text(
              '¿Ya te abrieron?',
              style: TextStyle(color: AppColors.gris600),
            ),
            const SizedBox(height: 12,),

            FilledButton(onPressed: onStart, 
            child: const Text("Empezar")
            ),
            const SizedBox(height: 8,),

            OutlinedButton(
              onPressed: onNoAnswer,
              child: const Text('No me abren'))
        ],
      ),
    );
}}
