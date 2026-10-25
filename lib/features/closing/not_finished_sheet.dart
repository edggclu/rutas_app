import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Lo que el técnico elige en "No lo terminé".
enum NotFinishedChoice { continueTomorrow, blocked } // "Sigo otro día" o "No pude seguir"

/// Hoja inferior con las dos opciones. Devuelve null si el técnico vuelve a la visita.
Future<NotFinishedChoice?> showNotFinishedSheet(BuildContext context) { // muestra la hoja
  return showModalBottomSheet<NotFinishedChoice>( // hoja que sube desde abajo
    context: context, // sobre esta pantalla
    backgroundColor: Colors.white, // fondo blanco
    shape: const RoundedRectangleBorder( // esquinas de arriba redondeadas
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding( // margen alrededor
      padding: EdgeInsets.fromLTRB(20, 24, 20, 16 + MediaQuery.of(ctx).padding.bottom), // deja espacio para la barra de gestos
      child: Column( // elementos uno debajo de otro
        mainAxisSize: MainAxisSize.min, // solo ocupa lo necesario
        crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
        children: [
          const Text( // título
            '¿Qué pasó?', // texto
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700), // grande y en negritas
          ),
          const SizedBox(height: 12), // espacio vertical
          _ChoiceCard( // opción 1
            color: AppColors.ok, // verde
            title: 'Sigo otro día', // título
            subtitle: 'Va bien, pero no alcanzó el día.', // descripción
            hint: 'Nadie tiene que hacer nada.', // aclaración
            onTap: () => Navigator.of(ctx).pop(NotFinishedChoice.continueTomorrow), // devuelve la opción
          ),
          const SizedBox(height: 10), // espacio vertical
          _ChoiceCard( // opción 2
            color: AppColors.rojo, // rojo
            title: 'No pude seguir', // título
            subtitle: 'Algo me detuvo y alguien tiene que resolverlo.', // descripción
            hint: 'Se avisa a la oficina.', // aclaración
            onTap: () => Navigator.of(ctx).pop(NotFinishedChoice.blocked), // devuelve la opción
          ),
          const SizedBox(height: 4), // espacio vertical
          Center( // centrado
            child: TextButton( // volver
              onPressed: () => Navigator.of(ctx).pop(), // cierra devolviendo null
              child: const Text('Volver a la visita'), // texto
            ),
          ),
        ],
      ),
    ),
  );
}

/// Tarjeta grande tocable con borde de color.
class _ChoiceCard extends StatelessWidget { // widget sin estado propio
  const _ChoiceCard({ // constructor
    required this.color, // color del borde y del título
    required this.title, // título
    required this.subtitle, // descripción
    required this.hint, // aclaración pequeña
    required this.onTap, // qué hacer al tocar
  });

  final Color color; // color
  final String title; // título
  final String subtitle; // descripción
  final String hint; // aclaración
  final VoidCallback onTap; // función al tocar

  @override
  Widget build(BuildContext context) { // dibuja la tarjeta
    return Material( // permite el efecto de toque
      color: Colors.white, // fondo blanco
      borderRadius: BorderRadius.circular(14), // esquinas redondeadas
      child: InkWell( // zona tocable
        borderRadius: BorderRadius.circular(14), // el efecto respeta las esquinas
        onTap: onTap, // al tocar
        child: Container( // caja con borde
          width: double.infinity, // todo el ancho
          padding: const EdgeInsets.all(16), // margen interno
          decoration: BoxDecoration( // estilo
            borderRadius: BorderRadius.circular(14), // esquinas redondeadas
            border: Border.all(color: color, width: 2), // borde de color
          ),
          child: Column( // textos uno debajo de otro
            crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
            children: [
              Text( // título
                title, // texto
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color), // grande y de color
              ),
              const SizedBox(height: 2), // espacio vertical
              Text(subtitle), // descripción
              const SizedBox(height: 4), // espacio vertical
              Text( // aclaración
                hint, // texto
                style: const TextStyle(fontSize: 12, color: AppColors.gris600), // pequeña y gris
              ),
            ],
          ),
        ),
      ),
    );
  }
}