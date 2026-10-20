import 'package:url_launcher/url_launcher.dart';

/// Abre el marcador del teléfono con el número. Devuelve true si se pudo abrir.
Future<bool> callPhone (String phone) async {
  try {
    return await launchUrl(Uri(scheme: 'tel', path: phone)); // abre el marcador
  } catch(_) {
    return false;
  }
}
/// Abre WhatsApp con una conversación con ese número. [text] es un mensaje ya escrito (opcional).
Future<bool> openWhatsApp(String phone, {String? text}) async { // devuelve true si se pudo abrir
  var digits = phone.replaceAll(RegExp(r'\D'), ''); // se queda solo con los dígitos
  if (digits.length == 10) digits = '52$digits'; // número de México de 10 dígitos: se le antepone el 52
  final query = text == null ? '' : '?text=${Uri.encodeComponent(text)}'; // el mensaje, convertido a formato de enlace
  try { // si algo falla, no se cae la app
    return await launchUrl( // abre el enlace de WhatsApp
      Uri.parse('https://wa.me/$digits$query'), // wa.me es el enlace oficial para abrir un chat
      mode: LaunchMode.externalApplication, // se abre en la app de WhatsApp
    );
  } catch (_) { // WhatsApp no instalado u otro error
    return false; // no se pudo
  }
}