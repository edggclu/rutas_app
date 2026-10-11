import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// Las horas viajan y se guardan en UTC; en pantalla se muestran en hora del
/// centro de México. Requiere `tzdata.initializeTimeZones()` en main().
const String kDisplayZone = 'America/Mexico_City';

String formatClock(DateTime utc) {
  final local = tz.TZDateTime.from(utc.toUtc(), tz.getLocation(kDisplayZone));
  return DateFormat('H:mm').format(local);
}

String formatLongDate(DateTime d) {
  final s = DateFormat("EEEE d 'de' MMMM", 'es_MX').format(d);
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
