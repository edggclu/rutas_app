import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:telyser_app/core/widgets/alert_box.dart';
import 'package:telyser_app/core/widgets/app_header.dart';
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/features/shared/run_undoable.dart';
import 'package:telyser_app/features/site/capture_photo.dart';

/// E4 · Solicitud para después: algo que el cliente pidió y no se puede hacer hoy.
class AddRequestScreen extends ConsumerStatefulWidget { // widget con estado
  const AddRequestScreen({super.key, required this.visit}); // recibe la visita

  final Visit visit; // la visita donde se hizo la solicitud

  @override
  ConsumerState<AddRequestScreen> createState() => _AddRequestScreenState(); // crea el estado
}

class _AddRequestScreenState extends ConsumerState<AddRequestScreen> { // el estado del formulario
  final _descCtrl = TextEditingController(); // controla la descripción
  final _whoCtrl = TextEditingController(); // controla "quién lo pidió"
  int _photos = 0; // cuántas fotos se tomaron en esta pantalla
  bool _saving = false; // true mientras se guarda

  @override
  void dispose() { // al cerrar la pantalla
    _descCtrl.dispose(); // libera el controlador de la descripción
    _whoCtrl.dispose(); // libera el de "quién"
    super.dispose(); // termina de limpiar
  }

  Future<void> _photo() async { // se ejecuta al tocar "Agregar foto"
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    try { // si algo falla, se avisa
      final ok = await capturePhoto( // abre la cámara
          ref, visitId: widget.visit.id, kind: 'request'); // la foto queda marcada como de solicitud
      if (ok && mounted) setState(() => _photos++); // si guardó, suma al contador
    } catch (_) { // la cámara falló
      messenger.showSnackBar(const SnackBar( // aviso sencillo
        content: Text('No se pudo guardar la foto.'), // mensaje
      ));
    }
  }

    Future<void> _save() async { // se ejecuta al tocar Guardar
    setState(() => _saving = true); // bloquea el botón
    final who = _whoCtrl.text.trim(); // quién la pidió
    await runUndoable( // guarda, cierra y muestra la barra
      context, ref, // dónde mostrar los avisos
      action: (a) => a.extras.addRequest( // el área de extras
        visitId: widget.visit.id, // visita
        description: _descCtrl.text.trim(), // descripción
        requestedBy: who.isEmpty ? null : who, // quién la pidió (opcional)
      ),
      message: 'Solicitud guardada', // texto de la barra
      after: AfterSave.pop, // cierra el formulario
      onError: () { // si falla
        if (mounted) setState(() => _saving = false); // desbloquea el botón
      },
    );
  }
  
  @override
  Widget build(BuildContext context) { // dibuja el formulario
    final bottom = MediaQuery.of(context).padding.bottom; // alto de la barra de gestos
    return Scaffold( // estructura de la pantalla
      body: Column( // elementos uno debajo de otro
        children: [
          AppHeader( // encabezado navy
            subtitle: widget.visit.job.folio, // arriba: el folio
            title: 'Solicitud para después', // título
            onBack: () => Navigator.of(context).pop(), // flecha para regresar
          ),
          Expanded( // ocupa el espacio que queda
            child: ListView( // contenido que se puede desplazar
              padding: const EdgeInsets.all(16), // margen de 16
              children: [
                const AlertBox( // aviso fijo
                  title: 'No se hace en esta visita', // título
                  body: 'Administración la cotizará como trabajo nuevo.', // texto
                ),
                const SizedBox(height: 12), // espacio vertical
                TextField( // campo de descripción
                  controller: _descCtrl, // su controlador
                  onChanged: (_) => setState(() {}), // revisa si ya se puede guardar
                  maxLines: 3, // hasta 3 renglones visibles
                  decoration: const InputDecoration( // etiqueta
                    labelText: 'Qué pidió el cliente', // texto
                    helperText: 'Ej. "Quiere cámaras en la alberca, pero no traigo material"', // ejemplo
                  ),
                ),
                const SizedBox(height: 12), // espacio vertical
                TextField( // campo "quién lo pidió"
                  controller: _whoCtrl, // su controlador
                  decoration: const InputDecoration(labelText: 'Quién lo pidió (opcional)'), // etiqueta
                ),
                const SizedBox(height: 12), // espacio vertical
                OutlinedButton.icon( // botón de foto
                  onPressed: _photo, // abre la cámara
                  icon: const Icon(Icons.photo_camera), // ícono
                  label: Text(_photos == 0 ? 'Agregar foto' : 'Agregar otra foto ($_photos)'), // texto con contador
                ),
              ],
            ),
          ),
          Container( // franja blanca de abajo con el botón
            color: Colors.white, // fondo blanco
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom), // margen interno
            child: FilledButton( // botón Guardar
              onPressed: _descCtrl.text.trim().isNotEmpty && !_saving ? _save : null, // solo con descripción
              child: const Text('Guardar solicitud'), // texto
            ),
          ),
        ],
      ),
    );
  }
}