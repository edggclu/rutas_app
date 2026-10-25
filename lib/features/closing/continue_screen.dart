import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/input_formatters.dart';
import 'package:telyser_app/domain/format.dart';
import 'package:telyser_app/domain/models/media_item.dart';
import 'package:telyser_app/features/shared/run_undoable.dart';
import 'package:telyser_app/providers/route_providers.dart';
import 'package:telyser_app/providers/settings_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/alert_box.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/slide_to_confirm.dart';
import '../../domain/rules/closing.dart';
import '../../domain/models/models.dart';
import '../site/capture_photo.dart';
import '../media/media_strip.dart';

/// C7a · Sigo otro día: lo que se usó, lo que queda en el sitio y lo que falta.
class ContinueScreen extends ConsumerStatefulWidget { // widget con estado
  const ContinueScreen({super.key, required this.visit}); // recibe la visita

  final Visit visit; // la visita que continúa mañana

  @override
  ConsumerState<ContinueScreen> createState() => _ContinueScreenState(); // crea el estado
}

class _ContinueScreenState extends ConsumerState<ContinueScreen> { // el estado del formulario
  final _leftCtrl = TextEditingController(); // controla "qué se queda en el sitio"
  final _missingCtrl = TextEditingController(); // controla "qué falta"
  final _slideKey = GlobalKey<SlideToConfirmState>(); // para regresar el deslizable si algo falla
  late final List<ChecklistItem> _materials = widget.visit.checklist.materials; // renglones de material de la lista de salida
  late final Map<int, num> _used = { // cantidad usada por renglón; empieza igual a lo planeado
    for (final i in _materials) i.id: i.quantity ?? 0, // id del renglón -> cantidad
  };
  bool _laidCable = false; // ¿hoy se tendió cable?

  @override
  void dispose() { // al cerrar la pantalla
    _leftCtrl.dispose(); // libera el controlador
    _missingCtrl.dispose(); // libera el controlador
    super.dispose(); // termina de limpiar
  }

  Future<void> _video() async { // graba el video del cableado
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    final settings = ref.read(settingsProvider).value; // parámetros (null mientras cargan)
    if (settings == null) { // sin parámetros no sabemos la duración máxima
      messenger.showSnackBar(const SnackBar(content: Text('Los parámetros aún no cargan.'))); // aviso
      return; // termina
    }
    try { // si algo falla, se avisa
      await captureVideo(ref, visitId: widget.visit.id, maxSeconds: settings.videoMaxS); // graba y guarda
    } catch (_) { // la cámara falló
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo guardar el video.'))); // aviso
    }
  }

    Future<void> _confirm() async { // se ejecuta al completar el deslizamiento
    await runUndoable( // guarda, cierra y muestra la barra
      context, ref, // dónde mostrar los avisos
      action: (a) => a.closing.continueTomorrow( // el área de cierre
        visitId: widget.visit.id, // visita
        materials: [ // material usado hoy
          for (final i in _materials) // por cada renglón
            MaterialUsed(id: i.id, text: i.text, planned: i.quantity ?? 0, used: _used[i.id] ?? 0), // planeado contra usado
        ],
        leftOnSite: _leftCtrl.text, // lo que se queda
        missing: _missingCtrl.text, // lo que falta
        laidCable: _laidCable, // si tendió cable
      ),
      message: 'Marcaste Sigo otro día', // texto de la barra
      after: AfterSave.popToRoot, // vuelve a Mi día
      onError: () => _slideKey.currentState?.reset(), // regresa el deslizable
    );
  }

  @override
  Widget build(BuildContext context) { // dibuja la pantalla
    final media = ref.watch(mediaForVisitProvider(widget.visit.id)).value ?? const <MediaItem>[]; // archivos de la visita
    final videos = media.where((m) => m.kind == MediaKind.cablingVideo).length; // videos del cableado
    final canConfirm = canContinueTomorrow( // ¿ya se puede continuar?
      missing: _missingCtrl.text, // lo que falta
      laidCable: _laidCable, // si tendió cable
      cablingVideos: videos, // videos grabados
    );
    final bottom = MediaQuery.of(context).padding.bottom; // alto de la barra de gestos

    return Scaffold( // estructura de la pantalla
      body: Column( // elementos uno debajo de otro
        children: [
          AppHeader( // encabezado navy
            subtitle: widget.visit.job.folio, // arriba: el folio
            title: 'Sigo otro día', // título
            onBack: () => Navigator.of(context).pop(), // flecha para regresar
          ),
          Expanded( // ocupa el espacio que queda
            child: ListView( // contenido que se puede desplazar
              padding: const EdgeInsets.all(16), // margen de 16
              children: [
                const Text( // título de la sección
                  'Material usado hoy', // texto
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700), // negritas
                ),
                const SizedBox(height: 4), // espacio vertical
                if (_materials.isEmpty) // si la visita no tenía lista de material
                  const Text( // aviso
                    'Esta visita no tenía lista de material.', // texto
                    style: TextStyle(color: AppColors.gris600), // gris
                  ),
                for (final i in _materials) // por cada renglón
                  _UsedRow( // fila con − y +
                    item: i, // el renglón
                    onChanged: (v) => _used[i.id] = v, // guarda la cantidad usada
                  ),
                const SizedBox(height: 16), // espacio vertical
                TextField( // qué se queda en el sitio
                  controller: _leftCtrl, // su controlador
                  maxLines: 2, // hasta 2 renglones visibles
                  decoration: const InputDecoration( // etiqueta
                    labelText: 'Qué se queda en el sitio (opcional)', // texto
                    helperText: 'Ej. "4 cámaras y el cable restante en el cuarto de mantenimiento"', // ejemplo
                  ),
                ),
                const SizedBox(height: 12), // espacio vertical
                TextField( // qué falta
                  controller: _missingCtrl, // su controlador
                  onChanged: (_) => setState(() {}), // revisa si ya se puede continuar
                  maxLines: 3, // hasta 3 renglones visibles
                  decoration: const InputDecoration( // etiqueta
                    labelText: 'Qué falta por hacer', // texto
                    helperText: 'Obligatorio: sirve para que otro técnico pueda continuar', // ayuda
                  ),
                ),
                SwitchListTile( // interruptor del cableado
                  contentPadding: EdgeInsets.zero, // sin margen extra
                  title: const Text('Hoy se tendió cable'), // texto
                  value: _laidCable, // valor actual
                  onChanged: (v) => setState(() => _laidCable = v), // al cambiar, lo guarda
                ),
                if (_laidCable) ...[ // si tendió cable, pide el video
                  const AlertBox( // aviso
                    title: 'Video del cableado', // título
                    body: 'Grábalo antes de que cierren el plafón.', // texto
                    background: AppColors.alertaSuave, // fondo ámbar claro
                    foreground: AppColors.alerta, // texto ámbar
                  ),
                  const SizedBox(height: 8), // espacio vertical
                  OutlinedButton.icon( // botón de video
                    onPressed: _video, // abre la cámara en modo video
                    icon: const Icon(Icons.videocam), // ícono
                    label: Text('Grabar video ($videos)'), // texto con contador
                  ),
                  if (videos > 0) ...[ // los videos grabados: se pueden ver y borrar
                    const SizedBox(height: 10),
                    MediaStrip(items: [for (final m in media) if (m.kind == MediaKind.cablingVideo) m]),
                  ],
                ],
              ],
            ),
          ),
          Container( // franja blanca de abajo con el deslizable
            color: Colors.white, // fondo blanco
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom), // margen interno
            child: SlideToConfirm( // deslizable
              key: _slideKey, // para poder regresarlo
              enabled: canConfirm, // solo con lo obligatorio lleno
              color: AppColors.ok, // verde
              label: 'Desliza: Sigo otro día', // texto
              onConfirmed: _confirm, // al completarlo, guarda
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de material: nombre, botón −, cantidad editable y botón +.
class _UsedRow extends StatefulWidget { // con estado: la cantidad cambia
  const _UsedRow({required this.item, required this.onChanged}); // constructor

  final ChecklistItem item; // el renglón de material
  final ValueChanged<num> onChanged; // avisa la nueva cantidad usada

  @override
  State<_UsedRow> createState() => _UsedRowState(); // crea el estado
}

class _UsedRowState extends State<_UsedRow> { // el estado de la fila
  late final TextEditingController _ctrl = TextEditingController( // controla el campo de cantidad
      text: formatNumber(widget.item.quantity ?? 0)); // empieza igual a lo planeado

  @override
  void dispose() { // al cerrar
    _ctrl.dispose(); // libera el controlador
    super.dispose(); // termina de limpiar
  }

  num get _current => num.tryParse(_ctrl.text.trim().replaceAll(',', '.')) ?? 0; // cantidad escrita (0 si no es número)

  void _set(num v) { // cambia la cantidad con los botones
    final value = v < 0 ? 0 : v; // nunca baja de cero
    _ctrl.text = formatNumber(value); // actualiza el campo
    widget.onChanged(value); // avisa a la pantalla
  }

  @override
  Widget build(BuildContext context) { // dibuja la fila
    return Padding( // margen vertical
      padding: const EdgeInsets.symmetric(vertical: 4), // 4 arriba y abajo
      child: Row( // elementos en horizontal
        children: [
          Expanded(child: Text(widget.item.text)), // nombre del material
          IconButton( // botón −
            onPressed: () => _set(_current - 1), // resta uno
            icon: const Icon(Icons.remove_circle_outline), // ícono
          ),
          SizedBox( // ancho fijo para el campo
            width: 64, // ancho
            child: TextField( // cantidad editable
              controller: _ctrl, // su controlador
              textAlign: TextAlign.center, // centrado
              keyboardType: const TextInputType.numberWithOptions(decimal: true), // teclado numérico
              inputFormatters: decimalInput, // no deja escribir letras
              onChanged: (_) => widget.onChanged(_current), // avisa lo escrito
            ),
          ),
          IconButton( // botón +
            onPressed: () => _set(_current + 1), // suma uno
            icon: const Icon(Icons.add_circle_outline), // ícono
          ),
        ],
      ),
    );
  }
}