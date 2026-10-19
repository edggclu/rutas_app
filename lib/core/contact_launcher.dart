import 'package:url_launcher/url_launcher.dart';

/// Abre el marcador del teléfono con el número. Devuelve true si se pudo abrir.
Future<bool> callPhone (String phone) async {
  try {
    return await launchUrl(Uri(scheme: 'tel', path: phone)); // abre el marcador
  } catch(_) {
    return false;
  }
}
/// Abre WhatsApp con una conversación con ese número. Devuelve true si se pudo abrir.
Future<bool> openWhatsApp(String phone) async {
  // ignore: unnecessary_string_escapes
  var digits = phone.replaceAll(RegExp('r\D'), ''); // quita espacios y guines, se queda solo con los digitos
  if (digits.length == 10) digits = '52$digits'; // lada de mexico hardcodeada
  try {
    return await launchUrl(
      Uri.parse('https://wa.me/$digits'),
      mode: LaunchMode.externalApplication,
    );
  } catch (_){
    return false;
  }
}