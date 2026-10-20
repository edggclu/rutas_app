import 'package:flutter/material.dart'; // widgets básicos
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget
import 'package:telyser_app/domain/models/models.dart';
import 'package:telyser_app/domain/rules/closing.dart';
import 'package:telyser_app/domain/rules/visit_state.dart';
import 'package:telyser_app/providers/route_providers.dart';

import '../warranty_card.dart'; // la tarjeta
import '../warranty_screen.dart'; // la pantalla de garantía

/// Tarjeta de garantía de En sitio: muestra si ya se documentó y abre la pantalla.
class WarrantySection extends ConsumerWidget { // widget que puede leer providers
  const WarrantySection({super.key, required this.visit}); // recibe la visita

  final Visit visit; // la visita de garantía

  @override
  Widget build(BuildContext context, WidgetRef ref) { // dibuja la sección
    final events = ref.watch(visitEventsProvider).value ?? const <VisitEvent>[]; // las acciones de la cola
    return WarrantyCard( // la tarjeta
      documented: warrantyDocumented(events, visit.id), // ¿ya se documentó?
      causeLabel: lastWarrantyCause(events, visit.id)?.label, // causa guardada
      onOpen: () => Navigator.of(context).push( // abre la pantalla de garantía
        MaterialPageRoute<void>(
          builder: (_) => WarrantyScreen(visit: visit), // con esta visita
        ),
      ),
    );
  }
}