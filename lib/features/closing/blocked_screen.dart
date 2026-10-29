import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/core/widgets/unsaved_guard.dart';
import 'package:telyser_app/core/widgets/toast.dart';
import 'package:telyser_app/domain/models/media_item.dart';
import 'package:telyser_app/features/shared/run_undoable.dart';
import 'package:telyser_app/providers/actions_provider.dart';
import 'package:telyser_app/providers/route_providers.dart';
import 'package:telyser_app/providers/settings_provider.dart';

import '../../core/contact_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/alert_box.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/choice_group.dart';
import '../../domain/rules/closing.dart';
import '../../domain/models/models.dart';
import '../site/capture_photo.dart';
import '../media/media_strip.dart';

const _emergencyNumber = '911'; // número de emergencias en México (no es un parámetro de la empresa)

/// C7b · No pude seguir: motivo, nota, fotos y ayuda.
class BlockedScreen extends ConsumerStatefulWidget { // widget con estado
  const BlockedScreen({super.key, required this.visit}); // recibe la visita

  final Visit visit; // la visita que se detiene

  @override
  ConsumerState<BlockedScreen> createState() => _BlockedScreenState(); // crea el estado
}

class _BlockedScreenState extends ConsumerState<BlockedScreen> { // el estado del formulario
  final _noteCtrl = TextEditingController(); // controla la nota
  BlockReason? _reason; // motivo elegido (null = aún no elige)
  IncidentKind? _kind; // subtipo de incidente
  bool _saving = false; // true mientras se guarda

  @override
  void dispose() { // al cerrar la pantalla
    _noteCtrl.dispose(); // libera el controlador
    super.dispose(); // termina de limpiar
  }

  final List<String> _photoIds = []; // fotos tomadas en esta pantalla (las de daño se muestran siempre)

  Future<void> _photo() async { // toma una foto
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    try { // si algo falla, se avisa
      final id = await capturePhoto( // abre la cámara y guarda
        ref,
        visitId: widget.visit.id, // visita
        kind: _reason == BlockReason.incident ? MediaKind.damage : MediaKind.progress, // los incidentes se marcan como daño
      );
      if (id != null && mounted) setState(() => _photoIds.add(id)); // la recuerda para mostrarla aquí
    } catch (_) { // la cámara falló
      messenger.toast('No se pudo guardar la foto');
    }
  }

  Future<void> _callOffice() async { // llama a la oficina
    final office = ref.read(settingsProvider).value?.officePhone; // teléfono de la oficina
    if (office != null) await callPhone(office); // marca si ya cargó
  }

  /// Abre WhatsApp con el ingeniero a cargo, con el mensaje ya escrito.
  Future<void> _askHelp() async { // se ejecuta al tocar "Pedir ayuda al ingeniero"
    final engineer = widget.visit.job.engineer; // ingeniero a cargo
    final phone = engineer?.phone; // su teléfono
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    final actions = ref.read(visitActionsProvider); // las acciones del técnico
    if (engineer == null || phone == null || phone.isEmpty) { // sin teléfono no se puede
      messenger.toast('No hay teléfono del ingeniero.');
      return; // termina
    }
    final note = _noteCtrl.text.trim(); // lo escrito en la nota
    final text = 'Hola ${engineer.name}, necesito ayuda en ${widget.visit.job.folio} ' // mensaje con folio...
        '(${widget.visit.place.name}): ${note.isEmpty ? 'no logro resolverlo' : note}'; // ...lugar y la nota
    final ok = await openWhatsApp(phone, text: text); // abre WhatsApp
    if (!ok) { // no se pudo abrir
      messenger.toast('No se pudo abrir WhatsApp.');
      return; // no se registra
    }
    await actions.closing.requestHelp(visitId: widget.visit.id); // registra la petición de ayuda
  }

    Future<void> _send() async { // se ejecuta al tocar Enviar
    setState(() => _saving = true); // bloquea el botón
    await runUndoable( // guarda, cierra y muestra la barra
      context, ref, // dónde mostrar los avisos
      action: (a) => a.closing.blockVisit( // el área de cierre
        visitId: widget.visit.id, // visita
        reason: _reason!, // motivo (ya validado)
        incidentKind: _reason == BlockReason.incident ? _kind : null, // subtipo solo si es incidente
        note: _noteCtrl.text, // nota
      ),
      message: 'Marcaste No pude seguir', // texto de la barra
      after: AfterSave.popToRoot, // vuelve a Mi día
      onError: () { // si falla
        if (mounted) setState(() => _saving = false); // desbloquea el botón
      },
    );
  }


  bool get _dirty => _reason != null || _kind != null || _noteCtrl.text.trim().isNotEmpty;
@override
  Widget build(BuildContext context) => UnsavedGuard(
        dirty: _dirty && !_saving,
        child: _form(context),
      );

  Widget _form(BuildContext context) { // dibuja la pantalla
    final media = ref.watch(mediaForVisitProvider(widget.visit.id)).value ?? const <MediaItem>[]; // archivos de la visita
    final damagePhotos = media.where((m) => m.kind == MediaKind.damage).length; // fotos del daño
    final shown = [for (final m in media) if (m.kind == MediaKind.damage || _photoIds.contains(m.id)) m]; // las que se muestran en la tira
    final canSend = canSendBlocked( // ¿ya se puede enviar?
      reason: _reason, // motivo
      incidentKind: _kind, // subtipo
      note: _noteCtrl.text, // nota
      damagePhotos: damagePhotos, // fotos del daño
    );
    final engineerPhone = widget.visit.job.engineer?.phone; // teléfono del ingeniero (null si no viene)
    final bottom = MediaQuery.of(context).padding.bottom; // alto de la barra de gestos

    return Scaffold( // estructura de la pantalla
      body: Column( // elementos uno debajo de otro
        children: [
          AppHeader( // encabezado navy
            subtitle: widget.visit.job.folio, // arriba: el folio
            title: 'No pude seguir', // título
            onBack: () => Navigator.of(context).maybePop(), // flecha para regresar (pregunta si hay cambios)
          ),
          Expanded( // ocupa el espacio que queda
            child: ListView( // contenido que se puede desplazar
              padding: const EdgeInsets.all(16), // margen de 16
              children: [
                const Text( // título de la sección
                  'Motivo', // texto
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700), // negritas
                ),
                const SizedBox(height: 8), // espacio vertical
                for (final r in BlockReason.values) // una tarjeta por motivo
                  _ReasonCard( // la tarjeta
                    reason: r, // el motivo
                    selected: _reason == r, // ¿es el elegido?
                    onTap: () => setState(() => _reason = r), // al tocar, lo elige
                  ),
                if (_reason == BlockReason.incident) ...[ // si es un incidente
                  const SizedBox(height: 8), // espacio vertical
                  ChoiceGroup<IncidentKind>( // tipo de incidente
                    title: 'Tipo de incidente', // título
                    options: [for (final k in IncidentKind.values) (k, k.label)], // las tres opciones
                    selected: _kind, // el elegido
                    onSelected: (v) => setState(() => _kind = v), // al elegir, lo guarda
                  ),
                  if (_kind == IncidentKind.accident) ...[ // accidente: primero se pide ayuda
                    const AlertBox( // aviso rojo
                      title: 'Pide ayuda', // título
                      body: 'Tu seguridad es lo primero.', // texto
                      background: AppColors.rojoSuave, // fondo rojo claro
                      foreground: AppColors.rojo, // texto rojo
                    ),
                    const SizedBox(height: 8), // espacio vertical
                    FilledButton( // llamar a emergencias
                      onPressed: () => callPhone(_emergencyNumber), // marca el 911
                      child: const Text('Llamar a emergencias'), // texto
                    ),
                    const SizedBox(height: 8), // espacio vertical
                    OutlinedButton( // llamar a la oficina
                      onPressed: _callOffice, // marca a la oficina
                      child: const Text('Llamar a la oficina'), // texto
                    ),
                  ],
                  if (_kind == IncidentKind.propertyDamage) // daño a la propiedad
                    const AlertBox( // aviso ámbar
                      title: 'Antes de tocar nada', // título
                      body: 'Toma fotos del daño tal como está. Es obligatorio para enviar.', // texto
                      background: AppColors.alertaSuave, // fondo ámbar claro
                      foreground: AppColors.alerta, // texto ámbar
                    ),
                ],
                if (_reason == BlockReason.cannotSolve) ...[ // si no puede resolverlo
                  const SizedBox(height: 8), // espacio vertical
                  OutlinedButton( // pedir ayuda al ingeniero
                    onPressed: engineerPhone == null || engineerPhone.isEmpty ? null : _askHelp, // sin teléfono, deshabilitado
                    child: const Text('Pedir ayuda al ingeniero'), // texto
                  ),
                  const Padding( // explicación
                    padding: EdgeInsets.only(top: 4), // 4 de margen superior
                    child: Text( // texto
                      'Si el ingeniero te guía, quizá te ahorras otra visita.', // mensaje
                      style: TextStyle(fontSize: 12, color: AppColors.gris600), // pequeño y gris
                    ),
                  ),
                ],
                const SizedBox(height: 16), // espacio vertical
                TextField( // nota escrita
                  controller: _noteCtrl, // su controlador
                  onChanged: (_) => setState(() {}), // revisa si ya se puede enviar
                  maxLines: 3, // hasta 3 renglones visibles
                  decoration: const InputDecoration( // etiqueta
                    labelText: 'Nota', // texto
                    helperText: 'Obligatoria. La nota de voz llega después.', // ayuda
                  ),
                ),
                const SizedBox(height: 12), // espacio vertical
                OutlinedButton.icon( // foto opcional
                  onPressed: _photo, // abre la cámara
                  icon: const Icon(Icons.photo_camera), // ícono
                  label: Text(_reason == BlockReason.incident // texto según el motivo
                      ? 'Agregar foto ($damagePhotos)' // en incidentes se cuenta
                      : 'Agregar foto (opcional)'), // en los demás es opcional
                ),
                if (shown.isNotEmpty) ...[ // las fotos de esta pantalla: se pueden abrir y borrar
                  const SizedBox(height: 10),
                  MediaStrip(items: shown),
                ],
              ],
            ),
          ),
          Container( // franja blanca de abajo con el botón
            color: Colors.white, // fondo blanco
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom), // margen interno
            child: FilledButton( // botón Enviar
              onPressed: canSend && !_saving ? _send : null, // null = deshabilitado
              child: const Text('Enviar'), // texto
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de un motivo, con a quién se avisa.
class _ReasonCard extends StatelessWidget { // widget sin estado propio
  const _ReasonCard({required this.reason, required this.selected, required this.onTap}); // constructor

  final BlockReason reason; // el motivo
  final bool selected; // ¿está elegido?
  final VoidCallback onTap; // qué hacer al tocar

  @override
  Widget build(BuildContext context) { // dibuja la tarjeta
    return Padding( // margen abajo
      padding: const EdgeInsets.only(bottom: 8), // 8 de margen inferior
      child: Material( // permite el efecto de toque
        color: selected ? AppColors.rojoSuave : Colors.white, // resaltada si está elegida
        borderRadius: BorderRadius.circular(12), // esquinas redondeadas
        child: InkWell( // zona tocable
          borderRadius: BorderRadius.circular(12), // el efecto respeta las esquinas
          onTap: onTap, // al tocar
          child: Container( // caja con borde
            width: double.infinity, // todo el ancho
            padding: const EdgeInsets.all(14), // margen interno
            decoration: BoxDecoration( // estilo
              borderRadius: BorderRadius.circular(12), // esquinas redondeadas
              border: Border.all( // borde
                color: selected ? AppColors.rojo : AppColors.gris200, // rojo si está elegida
                width: selected ? 2 : 1, // más grueso si está elegida
              ),
            ),
            child: Column( // textos uno debajo de otro
              crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
              children: [
                Text( // motivo
                  reason.label, // texto
                  style: const TextStyle(fontWeight: FontWeight.w700), // negritas
                ),
                Text( // a quién se avisa
                  reason.notifies, // texto
                  style: const TextStyle(fontSize: 12, color: AppColors.gris600), // pequeño y gris
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}