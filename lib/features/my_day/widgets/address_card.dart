import 'package:flutter/material.dart';
import 'package:telyser_app/core/map_launcher.dart';
import 'package:telyser_app/domain/models/models.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/toast.dart';

/// Dirección del lugar, con el botón para abrirla en Maps o Waze.
class AddressCard extends StatelessWidget { // widget sin estado propio
  const AddressCard({super.key, required this.place}); // recibe el lugar

  final Place place; // el lugar

  Future<void> _open(BuildContext context) async { // se ejecuta al tocar el botón
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    final ok = await openMap( // abre el mapa
      lat: place.lat, // latitud (puede faltar)
      lng: place.lng, // longitud (puede faltar)
      label: place.name, // nombre del lugar
      address: place.address, // dirección
    );
    if (!ok) messenger.toast('No se pudo abrir el mapa.'); // si ninguna app respondió, avisa
  }

  @override
  Widget build(BuildContext context) { // dibuja la tarjeta
    return AppCard( // la caja compartida
      child: Column( // elementos uno debajo de otro
        crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
        children: [
          Text( // la dirección
            place.address, // texto
            style: const TextStyle(fontWeight: FontWeight.w500), // seminegritas
          ),
          const SizedBox(height: 10), // espacio vertical
          FilledButton( // botón
            style: FilledButton.styleFrom( // estilo propio
              backgroundColor: AppColors.navy900, // fondo navy
              minimumSize: const Size.fromHeight(44), // altura mínima
            ),
            onPressed: () => _open(context), // abre el mapa
            child: const Text('Abrir en Maps / Waze'), // texto
          ),
        ],
      ),
    );
  }
}