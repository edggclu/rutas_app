import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/review_rules.dart';

/// Hoja inferior que pide la nota para regresar un trabajo.
/// Devuelve la nota escrita, o null si el ingeniero cancela.
Future<String?> showReturnSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true, // permite que suba con el teclado
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _ReturnSheet(),
  );
}

class _ReturnSheet extends StatefulWidget {
  const _ReturnSheet();

  @override
  State<_ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends State<_ReturnSheet> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + keyboard + bottom), // deja espacio para el teclado
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Regresar con nota', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'El técnico verá tu nota y el jefe de ruta recibirá la solicitud de otra visita.',
              style: TextStyle(color: AppColors.gris600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              onChanged: (_) => setState(() {}), // revisa si ya se puede enviar
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nota para el técnico',
                helperText: 'Ej. "Falta la foto del grabador grabando"',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canReturnJob(_noteCtrl.text) // la nota es obligatoria
                  ? () => Navigator.of(context).pop(_noteCtrl.text.trim())
                  : null,
              child: const Text('Enviar'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ],
        ),
      ),
    );
  }
}