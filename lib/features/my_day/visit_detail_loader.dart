import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telyser_app/features/my_day/visit_detail_screen.dart';
import 'package:telyser_app/providers/route_providers.dart';

/// Lee la visita actual por su id y se la pasa a la tarjeta
/// Asi al tarjeta se redibujara sola cuando cambia el estado 
class VisitDetailLoader extends ConsumerWidget{

  final int visitId;

  const VisitDetailLoader({super.key, required this.visitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(visitByIdProvider(visitId));
    if (visit == null) { // todavía no carga
      return const Scaffold(body: Center(child: CircularProgressIndicator())); // círculo de carga
    }
    return VisitDetailScreen(visit: visit); // la tarjeta con la visita actualizada
  }

}