import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/rules/extras.dart';
import 'package:telyser_app/domain/rules/visit_state.dart';
import 'package:telyser_app/providers/route_providers.dart';

import '../../../core/theme/app_colors.dart'; // colores
import '../../extras/add_extra_screen.dart'; // el formulario de extras
import '../../extras/add_request_screen.dart'; // el formulario de solicitudes

/// Botones "+ Extra" y "Solicitud después", con la lista de lo ya guardado.
class ExtrasSection extends ConsumerWidget { // widget que puede leer providers
  const ExtrasSection({super.key, required this.visit}); // recibe la visita

  final Visit visit; // la visita

  @override
  Widget build(BuildContext context, WidgetRef ref) { // dibuja la sección
    final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[]; // las acciones de la cola
    final extras = extrasOf(events, visit.id); // extras ya guardados de esta visita
    final requests = requestsOf(events, visit.id); // solicitudes ya guardadas de esta visita
    return Column( // elementos uno debajo de otro
      crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
      children: [
        Row( // dos botones lado a lado
          children: [
            Expanded( // cada botón ocupa la mitad
              child: OutlinedButton( // botón: extra
                onPressed: () => Navigator.of(context).push( // abre el formulario
                  MaterialPageRoute<void>( // pantalla nueva
                    builder: (_) => AddExtraScreen(visit: visit), // con esta visita
                  ),
                ),
                child: const Text('+ Extra'), // texto
              ),
            ),
            const SizedBox(width: 8), // espacio horizontal
            Expanded( // segunda mitad
              child: OutlinedButton( // botón: solicitud para después
                onPressed: () => Navigator.of(context).push( // abre el formulario
                  MaterialPageRoute<void>( // pantalla nueva
                    builder: (_) => AddRequestScreen(visit: visit), // con esta visita
                  ),
                ),
                child: const Text('Solicitud después'), // texto
              ),
            ),
          ],
        ),
        if (extras.isNotEmpty) ...[ // si ya registró extras
          const SizedBox(height: 16), // espacio vertical
          Text( // título de la lista
            'Extras (${extras.length})', // con el contador
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), // negritas
          ),
          const SizedBox(height: 4), // espacio vertical
          for (final x in extras) // por cada extra
            _EntryRow( // un renglón
              icon: Icons.add_circle_outline, // ícono
              text: x.label, // ej. "1 × Cámara IP 4 MP"
              tag: x.notInstalled ? 'No se instaló' : null, // etiqueta si es "no se instaló"
            ),
        ],
        if (requests.isNotEmpty) ...[ // si ya guardó solicitudes
          const SizedBox(height: 16), // espacio vertical
          Text( // título de la lista
            'Solicitudes para después (${requests.length})', // con el contador
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), // negritas
          ),
          const SizedBox(height: 4), // espacio vertical
          for (final r in requests) // por cada solicitud
            _EntryRow( // un renglón
              icon: Icons.schedule, // ícono de reloj
              text: r.description, // descripción
              tag: switch (r.origin) { // etiqueta según el origen
                RequestOrigin.otherPerson => 'La pidió otra persona', // la pidió otra persona
                RequestOrigin.creditHold => 'Saldo vencido', // el cliente tiene saldo vencido
                RequestOrigin.cannotDoNow => null, // la creó el técnico: sin etiqueta
              },
            ),
        ],
      ],
    );
  }
}

/// Un renglón de la lista: ícono, texto y una etiqueta opcional.
class _EntryRow extends StatelessWidget { // widget sin estado propio
  const _EntryRow({required this.icon, required this.text, this.tag}); // constructor

  final IconData icon; // ícono de la izquierda
  final String text; // texto principal
  final String? tag; // etiqueta de la derecha (opcional)

  @override
  Widget build(BuildContext context) { // dibuja el renglón
    return Padding( // margen vertical
      padding: const EdgeInsets.symmetric(vertical: 4), // 4 arriba y abajo
      child: Row( // elementos en horizontal
        children: [
          Icon(icon, size: 18, color: AppColors.gris600), // el ícono
          const SizedBox(width: 8), // espacio horizontal
          Expanded(child: Text(text)), // el texto ocupa el espacio disponible
          if (tag != null) // si hay etiqueta
            Text( // la etiqueta
              tag!, // texto
              style: const TextStyle( // estilo
                fontSize: 12, // tamaño
                fontWeight: FontWeight.w700, // negritas
                color: AppColors.alerta, // ámbar
              ),
            ),
        ],
      ),
    );
  }
}