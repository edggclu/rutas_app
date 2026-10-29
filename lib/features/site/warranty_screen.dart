import 'package:flutter/material.dart';
import '../../core/widgets/input_formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/core/widgets/unsaved_guard.dart';
import 'package:telyser_app/core/widgets/toast.dart';
import 'package:telyser_app/domain/models/media_item.dart';
import 'package:telyser_app/features/shared/run_undoable.dart';
import 'package:telyser_app/providers/route_providers.dart';
import 'package:telyser_app/providers/settings_provider.dart';

import '../../core/contact_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/alert_box.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/choice_group.dart';
import '../../domain/rules/closing.dart';
import '../../domain/models/models.dart';
import 'capture_photo.dart';
import '../media/media_strip.dart';

/// G1 · Bloque de garantía (provisional: el ingeniero debe definir más campos).
class WarrantyScreen extends ConsumerStatefulWidget { // widget con estado
  const WarrantyScreen({super.key, required this.visit}); // recibe la visita

  final Visit visit; // la visita de garantía

  @override
  ConsumerState<WarrantyScreen> createState() => _WarrantyScreenState(); // crea el estado
}

class _WarrantyScreenState extends ConsumerState<WarrantyScreen> { // el estado del formulario
  final _serialCtrl = TextEditingController(); // controla el campo del número de serie
  WarrantyCause? _cause; // causa elegida (null = aún no elige)
  bool _saving = false; // true mientras se guarda

  @override
  void dispose() { // al cerrar la pantalla
    _serialCtrl.dispose(); // libera el controlador
    super.dispose(); // termina de limpiar
  }

  int _count(List<MediaItem> media, MediaKind kind) => // cuenta archivos de un tipo
      media.where((m) => m.kind == kind).length; // los que coinciden con el tipo

  /// Elige una causa; si es externa, avisa que hay que llamar a la oficina antes de reparar (G1b).
  Future<void> _pickCause(WarrantyCause c) async { // c = causa tocada
    setState(() => _cause = c); // la guarda
    if (!c.isExternal) return; // si no es externa, no hay aviso
    final office = ref.read(settingsProvider).value?.officePhone; // teléfono de la oficina (null si aún no carga)
    await showDialog<void>( // ventana de aviso
      context: context, // sobre esta pantalla
      builder: (ctx) => AlertDialog( // la ventana
        title: const Text('Causa externa'), // título
        content: const Text('Llama a la oficina antes de reparar. Probablemente se cobre al cliente.'), // aviso
        actions: [ // botones
          TextButton( // llamar
            onPressed: office == null ? null : () => callPhone(office), // marca (no se registra: no cuenta para "No me abren")
            child: const Text('Llamar a la oficina'), // texto
          ),
          TextButton( // cerrar
            onPressed: () => Navigator.of(ctx).pop(), // cierra la ventana
            child: const Text('Entendido'), // texto
          ),
        ],
      ),
    );
  }

  Future<void> _photo(MediaKind kind) async { // toma una foto del tipo indicado
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    try { // si algo falla, se avisa
      await capturePhoto(ref, visitId: widget.visit.id, kind: kind); // abre la cámara y guarda
    } catch (_) { // la cámara falló
      messenger.toast('No se pudo guardar la foto.'); // aviso
    }
  }

    Future<void> _save() async { // se ejecuta al tocar Guardar
    setState(() => _saving = true); // bloquea el botón
    final serial = _serialCtrl.text.trim(); // serial escrito
    await runUndoable( // guarda, cierra y muestra la barra
      context, ref, // dónde mostrar los avisos
      action: (a) => a.closing.documentWarranty( // el área de cierre
        visitId: widget.visit.id, // visita
        cause: _cause!, // causa (ya validada)
        serial: serial.isEmpty ? null : serial, // null si solo fotografió la etiqueta
      ),
      message: 'Garantía documentada', // texto de la barra
      after: AfterSave.pop, // vuelve a En sitio
      onError: () { // si falla
        if (mounted) setState(() => _saving = false); // desbloquea el botón
      },
    );
  }


  bool get _dirty => _cause != null || _serialCtrl.text.trim().isNotEmpty;
@override
  Widget build(BuildContext context) => UnsavedGuard(
        dirty: _dirty && !_saving,
        child: _form(context),
      );

  Widget _form(BuildContext context) { // dibuja la pantalla
    final media = ref.watch(mediaForVisitProvider(widget.visit.id)).value ?? const <MediaItem>[]; // fotos de la visita
    final failure = _count(media, MediaKind.warranty); // fotos de la falla
    final label = _count(media, MediaKind.warrantySerial); // fotos de la etiqueta

    final guide = widget.visit.job.warrantyGuide; // guía de garantía (texto editable desde la web)
    final canSave = canSaveWarranty( // ¿ya se puede guardar?
      cause: _cause, // causa elegida
      failurePhotos: failure, // fotos de la falla
      serial: _serialCtrl.text, // serial escrito
      serialPhotos: label, // fotos de la etiqueta
    );
    final bottom = MediaQuery.of(context).padding.bottom; // alto de la barra de gestos

    return Scaffold( // estructura de la pantalla
      body: Column( // elementos uno debajo de otro
        children: [
          AppHeader( // encabezado navy
            subtitle: widget.visit.job.folio, // arriba: el folio
            title: 'Garantía', // título
            onBack: () => Navigator.of(context).maybePop(), // flecha para regresar (pregunta si hay cambios)
          ),
          Expanded( // ocupa el espacio que queda
            child: ListView( // contenido que se puede desplazar
              padding: const EdgeInsets.all(16), // margen de 16
              children: [
                if (guide != null) ...[ // si el trabajo trae guía de garantía
                  AlertBox( // caja ámbar con la guía
                    title: 'Guía de garantía', // título
                    body: guide, // texto de la guía
                    background: AppColors.alertaSuave, // fondo ámbar claro
                    foreground: AppColors.alerta, // texto ámbar
                  ),
                  const SizedBox(height: 12), // espacio vertical
                ],
                const AlertBox( // recordatorio fijo
                  title: 'No le prometas al cliente', // título
                  body: 'No le digas que entra en garantía. Eso lo decide administración.', // texto
                  background: AppColors.rojoSuave, // fondo rojo claro
                  foreground: AppColors.rojo, // texto rojo
                ),
                const SizedBox(height: 16), // espacio vertical
                ChoiceGroup<WarrantyCause>( // causas posibles
                  title: 'Causa de la falla', // título
                  options: [for (final c in WarrantyCause.values) (c, c.label)], // las seis opciones
                  selected: _cause, // la elegida
                  onSelected: _pickCause, // al elegir, la guarda y avisa si es externa
                ),
                OutlinedButton.icon( // foto de la falla
                  onPressed: () => _photo(MediaKind.warranty), // abre la cámara
                  icon: const Icon(Icons.photo_camera), // ícono
                  label: Text('Foto de la falla ($failure)'), // texto con contador
                ),
                if (failure > 0) ...[ // las fotos de la falla: se pueden abrir y borrar
                  const SizedBox(height: 8),
                  MediaStrip(items: [for (final m in media) if (m.kind == MediaKind.warranty) m]),
                ],
                const SizedBox(height: 16), // espacio vertical
                TextField( // número de serie escrito
                  controller: _serialCtrl, // su controlador
                  onChanged: (_) => setState(() {}), // revisa si ya se puede guardar
                  inputFormatters: shortText(60), // largo máximo
                  decoration: const InputDecoration(labelText: 'Número de serie'), // etiqueta
                ),
                const SizedBox(height: 8), // espacio vertical
                OutlinedButton.icon( // o foto de la etiqueta
                  onPressed: () => _photo(MediaKind.warrantySerial), // abre la cámara
                  icon: const Icon(Icons.qr_code_2), // ícono
                  label: Text('O foto de la etiqueta ($label)'), // texto con contador
                ),
                if (label > 0) ...[ // las fotos de la etiqueta
                  const SizedBox(height: 8),
                  MediaStrip(items: [for (final m in media) if (m.kind == MediaKind.warrantySerial) m]),
                ],
              ],
            ),
          ),
          Container( // franja blanca de abajo con el botón
            color: Colors.white, // fondo blanco
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom), // margen interno
            child: FilledButton( // botón Guardar
              onPressed: canSave && !_saving ? _save : null, // null = deshabilitado
              child: const Text('Guardar garantía'), // texto
            ),
          ),
        ],
      ),
    );
  }
}