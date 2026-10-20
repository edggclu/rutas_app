import 'package:flutter/material.dart'; // widgets básicos

import '../../core/theme/app_colors.dart'; // colores
import '../../domain/rules/extras.dart'; // ExtraEntry

/// Quién confirmó los extras.
class FinishConfirmation { // datos de la confirmación
  const FinishConfirmation(this.name, this.role); // constructor
  final String name; // nombre del contacto autorizado
  final String role; // cargo (puede ir vacío)
}

/// Hoja inferior que lista los extras y pide el nombre de quien los confirma.
/// Devuelve null si el técnico cancela.
Future<FinishConfirmation?> showFinishSheet( // muestra la hoja
  BuildContext context, { // dónde mostrarla
  required List<ExtraEntry> extras, // los extras de la visita
  String? contactName, // nombre del contacto autorizado, como ayuda
}) {
  return showModalBottomSheet<FinishConfirmation>( // hoja que sube desde abajo
    context: context, // sobre esta pantalla
    isScrollControlled: true, // permite que suba con el teclado
    backgroundColor: Colors.white, // fondo blanco
    shape: const RoundedRectangleBorder( // esquinas de arriba redondeadas
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FinishSheet(extras: extras, contactName: contactName), // el contenido
  );
}

class _FinishSheet extends StatefulWidget { // contenido con estado (los campos cambian)
  const _FinishSheet({required this.extras, this.contactName}); // constructor

  final List<ExtraEntry> extras; // extras a confirmar
  final String? contactName; // nombre sugerido

  @override
  State<_FinishSheet> createState() => _FinishSheetState(); // crea el estado
}

class _FinishSheetState extends State<_FinishSheet> { // el estado de la hoja
  final _nameCtrl = TextEditingController(); // controla el campo del nombre
  final _roleCtrl = TextEditingController(); // controla el campo del cargo

  @override
  void dispose() { // al cerrar la hoja
    _nameCtrl.dispose(); // libera el controlador del nombre
    _roleCtrl.dispose(); // libera el del cargo
    super.dispose(); // termina de limpiar
  }

  @override
  Widget build(BuildContext context) { // dibuja la hoja
    final keyboard = MediaQuery.of(context).viewInsets.bottom; // alto del teclado
    final bottom = MediaQuery.of(context).padding.bottom; // alto de la barra de gestos
    final name = _nameCtrl.text.trim(); // nombre escrito
    return Padding( // margen alrededor
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + keyboard + bottom), // deja espacio para el teclado
      child: SingleChildScrollView( // permite desplazar si no cabe
        child: Column( // elementos uno debajo de otro
          mainAxisSize: MainAxisSize.min, // solo ocupa lo necesario
          crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
          children: [
            const Text( // título
              'Confirma los extras', // texto
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700), // grande y en negritas
            ),
            const SizedBox(height: 4), // espacio vertical
            const Text( // explicación
              'El contacto autorizado debe confirmarlos escribiendo su nombre.', // texto
              style: TextStyle(color: AppColors.gris600), // gris
            ),
            const SizedBox(height: 12), // espacio vertical
            for (final x in widget.extras) // por cada extra
              Padding( // margen vertical
                padding: const EdgeInsets.symmetric(vertical: 3), // 3 arriba y abajo
                child: Row( // texto y etiqueta
                  children: [
                    Expanded(child: Text(x.label)), // ej. "1 × Cámara IP 4 MP"
                    if (x.notInstalled) // si es una nota de "no se instaló"
                      const Text( // etiqueta
                        'No se instaló', // texto
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.alerta), // ámbar
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12), // espacio vertical
            TextField( // nombre de quien confirma
              controller: _nameCtrl, // su controlador
              onChanged: (_) => setState(() {}), // revisa si ya se puede confirmar
              decoration: InputDecoration( // etiqueta
                labelText: 'Confirmó (nombre)', // texto
                helperText: widget.contactName == null ? null : 'Contacto autorizado: ${widget.contactName}', // ayuda
              ),
            ),
            const SizedBox(height: 10), // espacio vertical
            TextField( // cargo
              controller: _roleCtrl, // su controlador
              decoration: const InputDecoration(labelText: 'Cargo (opcional)'), // etiqueta
            ),
            const SizedBox(height: 16), // espacio vertical
            FilledButton( // confirmar
              onPressed: name.isEmpty // sin nombre no se puede confirmar
                  ? null // deshabilitado
                  : () => Navigator.of(context).pop( // cierra la hoja devolviendo la confirmación
                      FinishConfirmation(name, _roleCtrl.text.trim())),
              child: const Text('Confirmar cierre'), // texto
            ),
            const SizedBox(height: 8), // espacio vertical
            OutlinedButton( // cancelar
              onPressed: () => Navigator.of(context).pop(), // cierra devolviendo null
              child: const Text('Cancelar'), // texto
            ),
          ],
        ),
      ),
    );
  }
}