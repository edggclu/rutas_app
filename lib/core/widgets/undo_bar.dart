import 'dart:async';

import 'package:flutter/material.dart';
import 'package:telyser_app/core/theme/app_colors.dart';

/// Muestra "mensaje · quedan N s" con el botón Deshacer.
///
/// Recibe el ScaffoldMessengerState y no el context para poder mostrarse despues de la pantalla que se lanzo
/// el messenger vive en el MaterialApp y sobrevive a la navegacion.
/// 
/// No libera nada de la cola: pasalos los segundos, la accion se queda en grace hasta que el enviador llame a 'releaseExpired'
void showUndoBar(
  ScaffoldMessengerState messenger, {
    required String message,
    required int seconds,
    required Future<void> Function() onUndo,
  }
) {
  messenger
    ..hideCurrentMaterialBanner()
    ..showSnackBar(
      SnackBar(
        // Con un boton de accion, Flutter deja de el aviso fijo si no se indica
        // lo contrario. Aqui debe desaparecer solo al acabar la cuenta.
        persist: false,
        duration: Duration(seconds: seconds),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy900,
        content: _Countdown(message: message, seconds: seconds),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: AppColors.rojoSuave, 
          onPressed: (){
          onUndo();
          }
        ),
      )
    );
}

/// Texto con la cuenta regresiva (cambia cada segundo).
class _Countdown extends StatefulWidget {
  final String message;
  final int seconds;
  const _Countdown({required this.message, required this.seconds});

  @override
  State<StatefulWidget> createState() {
    return _CountdownState();
  }
  
}

class _CountdownState extends State<_Countdown> {

  late int _left = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if(!mounted) return;
      setState(() {
        _left = _left > 0 ? _left - 1 : 0;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.message} · quedan $_left s ',
      style: const TextStyle(color: Colors.white),
    );
  }

}
