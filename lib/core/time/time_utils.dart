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

/// "Hoy 14:05", "Ayer 20:10" o "20 oct 13:00", en hora del centro de México.
/// [now] se puede pasar para probarlo con un reloj fijo.
String formatRelativeDay(DateTime utc, {DateTime? now}) {
  final zone = tz.getLocation(kDisplayZone);
  final t = tz.TZDateTime.from(utc.toUtc(), zone);
  final today = tz.TZDateTime.from((now ?? DateTime.now()).toUtc(), zone);
  final days = DateTime(today.year, today.month, today.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  final clock = DateFormat('H:mm').format(t);
  if (days == 0) return 'Hoy $clock';
  if (days == 1) return 'Ayer $clock';
  return '${DateFormat('d MMM', 'es_MX').format(t)} $clock';
}
