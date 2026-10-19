import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:telyser_app/core/theme/app_colors.dart';
import 'package:telyser_app/core/widgets/alert_box.dart';
import 'package:telyser_app/core/widgets/app_header.dart';
import 'package:telyser_app/core/widgets/undo_bar.dart';
import 'package:telyser_app/data/providers.dart';
import 'package:telyser_app/domain/extras.dart';
import 'package:telyser_app/domain/models.dart';
import 'package:telyser_app/domain/product.dart';

final _money = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 0); // formato de dinero: $1,850

/// E1 · Agregar extra.
class AddExtraScreen extends ConsumerStatefulWidget { // widget con estado (los campos cambian)
  const AddExtraScreen({super.key, required this.visit}); // recibe la visita

  final Visit visit; // la visita donde se hace el extra

  @override
  ConsumerState<AddExtraScreen> createState() => _AddExtraScreenState(); // crea el estado
}

class _AddExtraScreenState extends ConsumerState<AddExtraScreen> { // el estado del formulario
  final _nameCtrl = TextEditingController(); // controla el campo "Qué"
  final _qtyCtrl = TextEditingController(text: '1'); // controla el campo "Cuánto" (empieza en 1)
  final _delayCtrl = TextEditingController(); // controla el campo de minutos de retraso

  Product? _product; // producto elegido del catálogo (null si lo escribe a mano)
  List<Product> _suggestions = const []; // sugerencias del catálogo mientras escribe
  ExtraSource? _source; // de dónde salió (null = aún no elige)
  ExtraReason? _reason; // por qué (null = aún no elige)
  bool? _authorized; // quién lo pidió: true = contacto autorizado, false = otra persona
  bool _notInstalled = false; // interruptor "es algo que NO se instaló"
  bool _delays = false; // interruptor "retrasa mis siguientes visitas"
  bool _saving = false; // true mientras se guarda (evita doble toque)

  @override
  void dispose() { // al cerrar la pantalla
    _nameCtrl.dispose(); // libera el controlador del nombre
    _qtyCtrl.dispose(); // libera el de la cantidad
    _delayCtrl.dispose(); // libera el del retraso
    super.dispose(); // termina de limpiar
  }

  /// Cantidad escrita: entero si no tiene decimales; null si no es un número.
  num? get _qty { // lee y convierte la cantidad
    final v = double.tryParse(_qtyCtrl.text.trim().replaceAll(',', '.')); // acepta coma o punto decimal
    if (v == null) return null; // no es un número
    return v % 1 == 0 ? v.toInt() : v; // 2.0 -> 2
  }

  int? get _delayMinutes => int.tryParse(_delayCtrl.text.trim()); // minutos de retraso (null si no es número)

  /// El botón Guardar se activa solo cuando todo lo necesario está lleno.
  bool get _canSave => // todas las condiciones juntas
      _nameCtrl.text.trim().isNotEmpty && // escribió qué es
      (_qty ?? 0) > 0 && // la cantidad es mayor que cero
      _source != null && // eligió de dónde salió
      _reason != null && // eligió por qué
      _authorized != null && // eligió quién lo pidió
      (!_delays || (_delayMinutes ?? 0) > 0); // si retrasa, escribió cuántos minutos

  /// Busca en el catálogo mientras el técnico escribe.
  Future<void> _onNameChanged(String text) async { // se ejecuta con cada letra
    if (_product != null && text != _product!.name) _product = null; // si editó el nombre, ya no es ese producto
    if (text.trim().length < 2) { // con menos de 2 letras no se busca
      setState(() => _suggestions = const []); // sin sugerencias
      return; // termina
    }
    final found = await ref.read(productRepositoryProvider).search(text); // busca en el catálogo
    if (!mounted) return; // si ya cerró la pantalla, no hace nada
    setState(() => _suggestions = found); // muestra las sugerencias
  }

  /// El técnico toca una sugerencia del catálogo.
  void _pick(Product p) { // p = el producto elegido
    setState(() { // redibuja la pantalla
      _product = p; // guarda el producto
      _nameCtrl.text = p.name; // pone su nombre en el campo
      _suggestions = const []; // oculta las sugerencias
    });
  }

  Future<void> _save() async { // se ejecuta al tocar Guardar
    setState(() => _saving = true); // bloquea el botón
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    final navigator = Navigator.of(context); // se guarda antes del await
    final actions = ref.read(visitActionsProvider); // las acciones del técnico
    final draft = ExtraDraft( // arma el borrador con lo que se llenó
      name: _nameCtrl.text.trim(), // nombre
      productId: _product?.id, // id del catálogo (null si lo escribió)
      quantity: _qty!, // cantidad (ya validada)
      unit: _product?.unit, // unidad del producto
      source: _source!, // origen (ya validado)
      reason: _reason!, // motivo (ya validado)
      requestedByAuthorized: _authorized!, // quién lo pidió (ya validado)
      isEquipment: _product?.isEquipment ?? true, // sin catálogo se asume equipo (lado seguro)
      notInstalled: _notInstalled, // ¿no se instaló?
      delayMinutes: _delays ? _delayMinutes : null, // retraso, solo si activó el interruptor
    );
    try { // si algo falla, se avisa
      final result = await actions.addExtra(visit: widget.visit, draft: draft); // aplica las reglas y guarda
      if (!mounted) return; // si ya cerró la pantalla, termina
      if (result.outcome != ExtraOutcome.register) { // si NO se registró como extra
        await showDialog<void>( // ventana que explica qué pasó
          context: context, // sobre esta pantalla
          builder: (ctx) => AlertDialog( // la ventana
            title: const Text('Se guardó como solicitud'), // título
            content: Text(result.outcome == ExtraOutcome.laterOtherPerson // texto según el motivo
                ? 'Solo el contacto autorizado puede pedir extras. Esto no se hace en esta visita: administración lo confirmará con el cliente.' // lo pidió otra persona
                : 'Este cliente tiene saldo vencido. No se agrega equipo sin autorización: quedó como solicitud para después y administración lo revisará.'), // saldo vencido
            actions: [ // botones de la ventana
              TextButton( // botón único
                onPressed: () => Navigator.of(ctx).pop(), // cierra la ventana
                child: const Text('Entendido'), // texto
              ),
            ],
          ),
        );
      }
      navigator.pop(); // cierra el formulario y vuelve a En sitio
      showUndoBar( // barra con cuenta regresiva
        messenger, // dónde mostrarla
        message: result.outcome == ExtraOutcome.register // texto según lo que pasó
            ? 'Extra guardado' // se registró
            : 'Solicitud guardada', // quedó como solicitud
        seconds: result.receipt.graceSeconds, // duración (parámetro del servidor)
        onUndo: () => actions.undo(result.receipt), // si toca Deshacer, se borra de la cola
      );
    } catch (_) { // no se pudo guardar
      if (!mounted) return; // si ya cerró la pantalla, termina
      setState(() => _saving = false); // desbloquea el botón
      messenger.showSnackBar(const SnackBar( // aviso sencillo
        content: Text('No se pudo guardar. Intenta de nuevo.'), // mensaje
      ));
    }
  }

  @override
  Widget build(BuildContext context) { // dibuja el formulario
    final contact = widget.visit.place.contact; // contacto principal del lugar
    final hasAuthorized = contact != null && contact.authorized; // ¿hay contacto autorizado?
    final product = _product; // atajo al producto elegido
    final bottom = MediaQuery.of(context).padding.bottom; // alto de la barra de gestos

    return Scaffold( // estructura de la pantalla
      body: Column( // elementos uno debajo de otro
        children: [
          AppHeader( // encabezado navy
            subtitle: widget.visit.job.folio, // arriba: el folio
            title: 'Agregar extra', // título
            onBack: () => Navigator.of(context).pop(), // flecha para regresar
          ),
          Expanded( // ocupa el espacio que queda
            child: ListView( // contenido que se puede desplazar
              padding: const EdgeInsets.all(16), // margen de 16
              children: [
                TextField( // campo "Qué"
                  controller: _nameCtrl, // su controlador
                  onChanged: (t) { // con cada letra
                    _onNameChanged(t); // busca en el catálogo
                    setState(() {}); // y revisa si ya se puede guardar
                  },
                  decoration: const InputDecoration(labelText: 'Qué (busca en el catálogo o escribe)'), // etiqueta
                ),
                if (_suggestions.isNotEmpty && product == null) // si hay sugerencias y aún no eligió
                  Container( // caja con las sugerencias
                    decoration: BoxDecoration( // estilo
                      color: Colors.white, // fondo blanco
                      borderRadius: BorderRadius.circular(10), // esquinas redondeadas
                      border: Border.all(color: AppColors.gris200), // borde gris claro
                    ),
                    child: Column( // una sugerencia debajo de otra
                      children: [
                        for (final p in _suggestions) // por cada sugerencia
                          ListTile( // un renglón tocable
                            dense: true, // más compacto
                            title: Text(p.name), // nombre del producto
                            trailing: Text(_money.format(p.price)), // precio aproximado
                            onTap: () => _pick(p), // al tocarlo, lo elige
                          ),
                      ],
                    ),
                  ),
                if (product != null) // si eligió un producto del catálogo
                  Padding( // margen arriba
                    padding: const EdgeInsets.only(top: 8), // 8 de margen superior
                    child: Text( // precio aproximado
                      'Precio aproximado: ${_money.format(product.price)} por ${product.unitLabel}', // ej. "$1,850 por pieza"
                      style: const TextStyle(color: AppColors.gris600, fontSize: 13), // gris y pequeño
                    ),
                  ),
                const SizedBox(height: 12), // espacio vertical
                TextField( // campo "Cuánto"
                  controller: _qtyCtrl, // su controlador
                  onChanged: (_) => setState(() {}), // revisa si ya se puede guardar
                  keyboardType: const TextInputType.numberWithOptions(decimal: true), // teclado numérico
                  decoration: InputDecoration( // etiqueta y unidad
                    labelText: 'Cuánto', // etiqueta
                    suffixText: product?.unitLabel, // unidad del producto (solo si hay)
                  ),
                ),
                const SizedBox(height: 16), // espacio vertical
                _ChoiceGroup<ExtraSource>( // grupo "De dónde salió"
                  title: 'De dónde salió', // título
                  options: [for (final s in ExtraSource.values) (s, s.label)], // las tres opciones
                  selected: _source, // la elegida
                  onSelected: (v) => setState(() => _source = v), // al elegir, la guarda
                ),
                _ChoiceGroup<ExtraReason>( // grupo "Por qué"
                  title: 'Por qué', // título
                  options: [for (final r in ExtraReason.values) (r, r.label)], // las dos opciones
                  selected: _reason, // la elegida
                  onSelected: (v) => setState(() => _reason = v), // al elegir, la guarda
                ),
                _ChoiceGroup<bool>( // grupo "Quién lo pidió"
                  title: 'Quién lo pidió', // título
                  options: [
                    (true, hasAuthorized ? 'El contacto autorizado (${contact.name})' : 'El contacto autorizado'), // con su nombre si existe
                    (false, 'Otra persona'), // otra persona
                  ],
                  disabled: hasAuthorized ? const {} : const {true}, // sin contacto autorizado, esa opción se bloquea
                  selected: _authorized, // la elegida
                  onSelected: (v) => setState(() => _authorized = v), // al elegir, la guarda
                ),
                SwitchListTile( // interruptor "no se instaló"
                  contentPadding: EdgeInsets.zero, // sin margen extra
                  title: const Text('Es algo que NO se instaló'), // texto
                  subtitle: const Text('Ej. "El cliente ya no quiso la cámara del pasillo"'), // ejemplo
                  value: _notInstalled, // valor actual
                  onChanged: (v) => setState(() => _notInstalled = v), // al cambiar, lo guarda
                ),
                SwitchListTile( // interruptor "retrasa mis visitas"
                  contentPadding: EdgeInsets.zero, // sin margen extra
                  title: const Text('Esto retrasa mis siguientes visitas'), // texto
                  value: _delays, // valor actual
                  onChanged: (v) => setState(() => _delays = v), // al cambiar, lo guarda
                ),
                if (_delays) // si retrasa, pide cuánto
                  TextField( // campo de minutos
                    controller: _delayCtrl, // su controlador
                    onChanged: (_) => setState(() {}), // revisa si ya se puede guardar
                    keyboardType: TextInputType.number, // teclado numérico
                    decoration: const InputDecoration( // etiqueta
                      labelText: '¿Cuánto tiempo tomará? (minutos)', // texto
                      helperText: 'Se avisa al jefe de ruta', // ayuda
                    ),
                  ),
                const SizedBox(height: 16), // espacio vertical
                const AlertBox( // recordatorio permanente
                  title: 'Recuérdale al cliente', // título
                  body: 'Los extras se cobran aparte.', // texto
                ),
              ],
            ),
          ),
          Container( // franja blanca de abajo con el botón
            color: Colors.white, // fondo blanco
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom), // margen interno
            child: FilledButton( // botón Guardar
              onPressed: _canSave && !_saving ? _save : null, // null = deshabilitado
              child: const Text('Guardar extra'), // texto
            ),
          ),
        ],
      ),
    );
  }
}

/// Un grupo de opciones tipo chip: una sola elegida a la vez.
class _ChoiceGroup<T> extends StatelessWidget { // T = tipo del valor (enum o bool)
  const _ChoiceGroup({ // constructor
    required this.title, // título del grupo
    required this.options, // lista de (valor, texto)
    required this.selected, // el valor elegido (null = ninguno)
    required this.onSelected, // qué hacer al elegir
    this.disabled = const {}, // valores que no se pueden elegir
  });

  final String title; // título
  final List<(T, String)> options; // opciones: pares (valor, texto)
  final T? selected; // el valor elegido
  final ValueChanged<T> onSelected; // función al elegir
  final Set<T> disabled; // valores bloqueados

  @override
  Widget build(BuildContext context) { // dibuja el grupo
    return Padding( // margen abajo
      padding: const EdgeInsets.only(bottom: 12), // 12 de margen inferior
      child: Column( // título y chips
        crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
        children: [
          Text( // título
            title, // texto
            style: const TextStyle( // estilo
              fontSize: 13, // tamaño
              fontWeight: FontWeight.w700, // negritas
              color: AppColors.gris600, // gris
            ),
          ),
          const SizedBox(height: 6), // espacio vertical
          Wrap( // chips en fila, que bajan de renglón si no caben
            spacing: 8, // espacio horizontal
            runSpacing: 8, // espacio vertical
            children: [
              for (final (value, label) in options) // por cada opción
                ChoiceChip( // chip elegible
                  label: Text(label), // texto
                  selected: selected == value, // ¿es la elegida?
                  onSelected: disabled.contains(value) // si está bloqueada
                      ? null // no responde
                      : (_) => onSelected(value), // si no, avisa cuál se eligió
                ),
            ],
          ),
        ],
      ),
    );
  }
}