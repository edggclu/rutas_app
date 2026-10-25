import 'package:flutter/material.dart';

/// Avisos cortos. Se usa sobre el `ScaffoldMessenger` que se guardó ANTES de un
/// `await` (después de un `await` ya puede no haber `context`).
extension ToastMessenger on ScaffoldMessengerState { // agrega un método al messenger
  void toast(String message) => // muestra un aviso corto abajo
      showSnackBar(SnackBar(content: Text(message))); // el aviso con el texto recibido
}