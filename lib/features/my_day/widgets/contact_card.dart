import 'package:flutter/material.dart'; // widgets básicos
import 'package:telyser_app/domain/models/models.dart';

import '../../../core/contact_launcher.dart'; // callPhone y openWhatsApp
import '../../../core/theme/app_colors.dart'; // colores
import '../../../core/widgets/app_card.dart'; // la tarjeta compartida
import '../../../core/widgets/toast.dart'; // avisos cortos

/// Contacto del lugar, con botones para llamar y mandar WhatsApp.
/// (Pendiente: que cada toque quede en la bitácora, como pide el documento.)
class ContactCard extends StatelessWidget { // widget sin estado propio
  const ContactCard({super.key, required this.contact}); // recibe el contacto

  final Contact contact; // el contacto principal del lugar

  Future<void> _call(BuildContext context) async { // se ejecuta al tocar "Llamar"
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    if (!await callPhone(contact.phone)) messenger.toast('No se pudo llamar.'); // abre el marcador; si falla, avisa
  }

  Future<void> _whatsapp(BuildContext context) async { // se ejecuta al tocar "WhatsApp"
    final messenger = ScaffoldMessenger.of(context); // se guarda antes del await
    if (!await openWhatsApp(contact.phone)) messenger.toast('No se pudo abrir WhatsApp.'); // abre WhatsApp; si falla, avisa
  }

  @override
  Widget build(BuildContext context) { // dibuja la tarjeta
    return AppCard( // la caja compartida
      child: Row( // datos a la izquierda, botones a la derecha
        children: [
          Expanded( // los datos ocupan el espacio disponible
            child: Column( // nombre, cargo y teléfono
              crossAxisAlignment: CrossAxisAlignment.start, // alineados a la izquierda
              children: [
                Text( // nombre
                  contact.name, // texto
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), // negritas
                ),
                if (contact.role != null) // si tiene cargo
                  Text( // el cargo
                    contact.role!, // texto
                    style: const TextStyle(fontSize: 12, color: AppColors.gris600), // pequeño y gris
                  ),
                Text( // teléfono
                  contact.phone, // texto
                  style: const TextStyle( // estilo
                    fontSize: 12, // tamaño
                    fontWeight: FontWeight.w500, // seminegritas
                    color: AppColors.gris600, // gris
                  ),
                ),
              ],
            ),
          ),
          _SmallButton( // botón: llamar
            label: 'Llamar', // texto
            color: AppColors.navy900, // fondo navy
            onTap: () => _call(context), // marca
          ),
          const SizedBox(width: 8), // espacio horizontal
          _SmallButton( // botón: WhatsApp
            label: 'WhatsApp', // texto
            color: AppColors.ok, // fondo verde
            onTap: () => _whatsapp(context), // abre WhatsApp
          ),
        ],
      ),
    );
  }
}

/// Botón chico de color.
class _SmallButton extends StatelessWidget { // widget sin estado propio
  const _SmallButton({required this.label, required this.color, required this.onTap}); // constructor

  final String label; // texto
  final Color color; // color de fondo
  final VoidCallback onTap; // qué hacer al tocar

  @override
  Widget build(BuildContext context) { // dibuja el botón
    return Material( // permite el efecto de toque
      color: color, // fondo
      borderRadius: BorderRadius.circular(10), // esquinas redondeadas
      child: InkWell( // zona tocable
        borderRadius: BorderRadius.circular(10), // el efecto respeta las esquinas
        onTap: onTap, // al tocar
        child: Padding( // margen interno
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), // 12 a los lados, 9 arriba y abajo
          child: Text( // el texto
            label, // texto
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), // blanco
          ),
        ),
      ),
    );
  }
}