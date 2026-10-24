import 'enums.dart'; // JobType
import 'payload.dart'; // lectores tolerantes

/// En qué punto de la revisión del ingeniero está un trabajo que el técnico terminó.
enum MyJobStatus {
  toValidate('to_validate'),
  validated('validated'),
  returned('returned');

  const MyJobStatus(this.code);
  final String code; // el texto que viaja en el JSON

  /// Un valor desconocido se lee como "por validar": es el estado más neutro.
  static MyJobStatus parse(String? s) =>
      lookup(values, s, (v) => v.code) ?? MyJobStatus.toValidate;
}

/// Un trabajo terminado por el técnico y lo que el ingeniero decidió de él.
class MyJob {
  const MyJob({
    required this.id,
    required this.folio,
    required this.type,
    required this.clientName,
    required this.placeName,
    required this.closedAt,
    required this.status,
    this.engineerName,
    this.reviewedAt,
    this.engineerNote,
  });

  final int id;
  final String folio;
  final JobType type;
  final String clientName;
  final String placeName;
  final DateTime closedAt; // siempre en UTC
  final MyJobStatus status;
  final String? engineerName;
  final DateTime? reviewedAt; // cuándo lo revisó el ingeniero (UTC)
  final String? engineerNote; // solo viene cuando fue regresado

  factory MyJob.fromJson(Map<String, dynamic> j) => MyJob(
        id: readInt(j, 'id') ?? 0,
        folio: readString(j, 'folio') ?? '',
        type: JobType.parse(readString(j, 'type')),
        clientName: readString(j, 'client') ?? '',
        placeName: readString(j, 'place') ?? '',
        closedAt: DateTime.tryParse(readString(j, 'closed_at') ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        status: MyJobStatus.parse(readString(j, 'review_status')),
        engineerName: readString(j, 'engineer'),
        reviewedAt: DateTime.tryParse(readString(j, 'reviewed_at') ?? '')?.toUtc(),
        engineerNote: readString(j, 'engineer_note'),
      );
}

/// Ordena para que lo que pide acción vaya primero: regresados, por validar y validados.
/// Dentro de cada grupo, lo más reciente arriba.
List<MyJob> sortMyJobs(Iterable<MyJob> jobs) {
  const order = [MyJobStatus.returned, MyJobStatus.toValidate, MyJobStatus.validated];
  final list = jobs.toList();
  list.sort((a, b) {
    final byStatus = order.indexOf(a.status).compareTo(order.indexOf(b.status));
    return byStatus != 0 ? byStatus : b.closedAt.compareTo(a.closedAt);
  });
  return list;
}
