import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Muestra "mensaje · quedan N s" con el botón Deshacer.
///
/// Recibe el ScaffoldMessengerState y no el context para poder mostrarse después de
/// cerrar la pantalla que la lanzó: el messenger vive en el MaterialApp y sobrevive
/// a la navegación.
///
/// No libera nada de la cola: pasados los segundos, la acción se queda en grace hasta
/// que el enviador llame a releaseExpired.
void showUndoBar( // muestra la barra
  ScaffoldMessengerState messenger, { // dónde mostrarla
  required String message, // texto, por ejemplo "Marcaste Llegué"
  required int seconds, // cuánto dura el tiempo para deshacer
  required Future<void> Function() onUndo, // qué hacer si toca Deshacer
}) {
  final deadline = DateTime.now().add(Duration(seconds: seconds)); // la hora exacta en que termina el tiempo
  messenger
    ..removeCurrentSnackBar() // quita YA la barra anterior (si no, la nueva se encola detrás y se ve el mensaje viejo)
    ..showSnackBar( // muestra la nueva
      SnackBar(
        // Con un botón de acción, Flutter deja el aviso fijo si no se indica lo
        // contrario. Aquí debe desaparecer solo al acabar la cuenta.
        persist: false, // no se queda fijo
        duration: Duration(seconds: seconds), // desaparece al terminar el tiempo
        behavior: SnackBarBehavior.floating, // flota sobre la pantalla
        backgroundColor: AppColors.navy900, // fondo navy
        content: _Countdown(message: message, deadline: deadline), // el texto con la cuenta regresiva
        action: SnackBarAction( // el botón
          label: 'Deshacer', // texto
          textColor: AppColors.rojoSuave, // color del texto
          onPressed: () { // al tocarlo
            onUndo(); // deshace la acción
          },
        ),
      ),
    );
}

/// Texto con la cuenta regresiva. Calcula lo que falta desde la hora límite, así que
/// si Flutter reconstruye la barra (por ejemplo, al abrir otra pantalla) no se reinicia.
class _Countdown extends StatefulWidget { // widget con estado: se redibuja cada instante
  const _Countdown({required this.message, required this.deadline}); // constructor

  final String message; // texto de la acción
  final DateTime deadline; // hora en que termina el tiempo

  @override
  State<_Countdown> createState() => _CountdownState(); // crea el estado
}

class _CountdownState extends State<_Countdown> { // el estado del texto
  Timer? _timer; // el reloj que lo redibuja

  @override
  void initState() { // al crearse
    super.initState(); // lo de siempre
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) { // cada cuarto de segundo
      if (!mounted) return; // si ya no está en pantalla, no hace nada
      setState(() {}); // redibuja para actualizar los segundos
    });
  }

  @override
  void dispose() { // al desaparecer
    _timer?.cancel(); // detiene el reloj
    super.dispose(); // termina de limpiar
  }

  /// Segundos que faltan, redondeados hacia arriba (10, 9, 8... 1, 0).
  int get _left { // calcula lo que falta
    final ms = widget.deadline.difference(DateTime.now()).inMilliseconds; // milisegundos hasta la hora límite
    return ms <= 0 ? 0 : (ms / 1000).ceil(); // nunca negativo
  }

  @override
  Widget build(BuildContext context) { // dibuja el texto
    return Text( // el mensaje con la cuenta
      '${widget.message} · quedan $_left s', // ej. "Marcaste Llegué · quedan 7 s"
      style: const TextStyle(color: Colors.white), // blanco
    );
  }
}