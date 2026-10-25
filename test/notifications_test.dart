import 'dart:convert'; // json.decode para leer el JSON de prueba
import 'dart:io'; // File para leer el archivo de prueba

import 'package:flutter_test/flutter_test.dart'; // herramientas de prueba
import 'package:telyser_app/core/time/time_utils.dart'; // formatRelativeDay
import 'package:telyser_app/domain/models/notification_models.dart'; // lo que se prueba
import 'package:telyser_app/domain/models/payload.dart'; // readMaps
import 'package:intl/date_symbol_data_local.dart'; // initializeDateFormatting
import 'package:timezone/data/latest.dart' as tzdata; // zonas horarias

void main() {
  late List<AppNotification> list;

  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting('es_MX'); // como en main()
  });

  setUp(() {
    final raw = json.decode(File('assets/mock/notifications.json').readAsStringSync()) as Map<String, dynamic>;
    list = [for (final m in readMaps(raw, 'notifications')) AppNotification.fromJson(m)];
  });

  test('notifications.json trae avisos de cada tipo conocido', () {
    expect(list.map((n) => n.type).toSet(),
        containsAll([NoticeType.routeChanged, NoticeType.jobReturned, NoticeType.jobValidated, NoticeType.planUpdated]));
  });

  test('un tipo desconocido se lee como otro y se muestra igual', () {
    expect(NoticeType.parse('algo_nuevo'), NoticeType.other);
    expect(NoticeType.parse(null), NoticeType.other);
    expect(NoticeType.parse(''), NoticeType.other);
  });

  test('cuenta los avisos sin leer', () {
    expect(unreadCount(list), 2);
    expect(unreadCount(list.map((n) => n.asRead())), 0);
  });

  test('ordena lo más reciente primero', () {
    final sorted = sortNotifications(list.reversed);
    expect(sorted.first.id, 5);
    expect(sorted.last.id, 1);
  });

  test('un aviso con datos raros no rompe la lectura', () {
    final n = AppNotification.fromJson({'id': 'x', 'title': 3});
    expect(n.id, 0);
    expect(n.title, '');
    expect(n.read, isFalse);
  });

  test('la hora se muestra como hoy, ayer o fecha, en hora de México', () {
    final now = DateTime.utc(2026, 10, 24, 18); // 12:00 en México
    expect(formatRelativeDay(DateTime.utc(2026, 10, 24, 14, 5), now: now), 'Hoy 8:05');
    expect(formatRelativeDay(DateTime.utc(2026, 10, 23, 20, 10), now: now), 'Ayer 14:10');
    expect(formatRelativeDay(DateTime.utc(2026, 10, 20, 13), now: now), contains('7:00'));
  });
}
