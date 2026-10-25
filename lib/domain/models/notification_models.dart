import 'payload.dart';

/// Qué tipo de aviso es. Un tipo que la app no conoce se lee como [other]: se muestra igual.
enum NoticeType {
  routeChanged('route_changed'),
  jobReturned('job_returned'),
  jobValidated('job_validated'),
  planUpdated('plan_updated'),
  other('');

  const NoticeType(this.code);
  final String code; // el texto que viaja en el JSON

  static NoticeType parse(String? s) =>
      values.firstWhere((t) => t.code.isNotEmpty && t.code == s, orElse: () => NoticeType.other);
}

/// Un aviso para el usuario. El servidor ya escribe el título y el texto.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.visitId,
  });

  final int id;
  final NoticeType type;
  final String title;
  final String body;
  final DateTime createdAt; // siempre en UTC
  final bool read;
  final int? visitId; // la visita a la que se refiere, si hay

  AppNotification asRead() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        read: true,
        visitId: visitId,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: readInt(j, 'id') ?? 0,
        type: NoticeType.parse(readString(j, 'type')),
        title: readString(j, 'title') ?? '',
        body: readString(j, 'body') ?? '',
        createdAt: DateTime.tryParse(readString(j, 'created_at') ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        read: readBool(j, 'read') ?? false,
        visitId: readInt(j, 'visit_id'),
      );
}

/// Los avisos sin leer.
int unreadCount(Iterable<AppNotification> list) => list.where((n) => !n.read).length;

/// Lo más reciente primero.
List<AppNotification> sortNotifications(Iterable<AppNotification> list) =>
    list.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
