import 'package:telyser_app/domain/models/enums.dart';
import 'package:telyser_app/domain/models/models.dart';

import 'closing_models.dart'; // WarrantyCause
import 'media_item.dart'; // MediaKind
import 'payload.dart'; // lectores tolerantes

/// Una foto de un trabajo terminado, tal como la ve el ingeniero.
class ReviewPhoto {
  const ReviewPhoto({required this.id, required this.kind, required this.src, this.caption});

  final int id;
  final MediaKind kind;
  final String src; // un asset en las pruebas; una URL con la API real
  final String? caption;

  factory ReviewPhoto.fromJson(Map<String, dynamic> j) => ReviewPhoto(
        id: readInt(j, 'id') ?? 0,
        kind: MediaKind.tryFromCode(readString(j, 'kind')) ?? MediaKind.progress,
        src: readString(j, 'src') ?? '',
        caption: readString(j, 'caption'),
      );
}

/// Un extra que el técnico registró en el trabajo.
class ReviewExtra {
  const ReviewExtra({required this.name, required this.quantity, required this.notInstalled});

  final String name;
  final num quantity;
  final bool notInstalled;

  factory ReviewExtra.fromJson(Map<String, dynamic> j) => ReviewExtra(
        name: readString(j, 'name') ?? '',
        quantity: readNum(j, 'quantity') ?? 1,
        notInstalled: readBool(j, 'not_installed') ?? false,
      );
}

/// Lo que el técnico documentó de una garantía y el dictamen del ingeniero.
class ReviewWarranty {
  const ReviewWarranty({this.cause, this.serial, this.verdict});

  final WarrantyCause? cause; // causa que eligió el técnico
  final String? serial;
  final WarrantyCause? verdict; // dictamen del ingeniero (null = todavía no)

  /// Pide dictamen cuando el técnico no supo la causa y el ingeniero aún no la fija.
  bool get needsVerdict => cause == WarrantyCause.unknown && verdict == null;

  ReviewWarranty withVerdict(WarrantyCause c) =>
      ReviewWarranty(cause: cause, serial: serial, verdict: c);

  factory ReviewWarranty.fromJson(Map<String, dynamic> j) => ReviewWarranty(
        cause: WarrantyCause.tryFromCode(readString(j, 'cause')),
        serial: readString(j, 'serial'),
        verdict: WarrantyCause.tryFromCode(readString(j, 'verdict')),
      );
}

/// Un trabajo terminado que espera validación.
class ReviewJob {
  const ReviewJob({
    required this.id,
    required this.folio,
    required this.type,
    required this.coverage,
    required this.clientName,
    required this.placeName,
    required this.technicianName,
    required this.closedAt,
    required this.photos,
    required this.extras,
    this.notes,
    this.warranty,
    this.plan,
  });

  final int id;
  final String folio;
  final JobType type;
  final Coverage coverage;
  final String clientName;
  final String placeName;
  final String technicianName;
  final DateTime closedAt; // siempre en UTC
  final String? notes; // notas del técnico
  final List<ReviewPhoto> photos;
  final List<ReviewExtra> extras;
  final ReviewWarranty? warranty; // solo en garantías
  final Plan? plan; // el plan del ingeniero, si existía

  bool get needsVerdict => warranty?.needsVerdict ?? false;

  /// Las fotos que sirven para dictaminar: la falla y la etiqueta del serial.
  List<ReviewPhoto> get failurePhotos => [
        for (final p in photos)
          if (p.kind == MediaKind.warranty || p.kind == MediaKind.warrantySerial) p,
      ];

  ReviewJob withVerdict(WarrantyCause cause) => ReviewJob(
        id: id,
        folio: folio,
        type: type,
        coverage: coverage,
        clientName: clientName,
        placeName: placeName,
        technicianName: technicianName,
        closedAt: closedAt,
        photos: photos,
        extras: extras,
        notes: notes,
        warranty: warranty?.withVerdict(cause),
        plan: plan,
      );

  factory ReviewJob.fromJson(Map<String, dynamic> j) {
    final warranty = j['warranty'];
    final plan = j['plan'];
    return ReviewJob(
      id: readInt(j, 'id') ?? 0,
      folio: readString(j, 'folio') ?? '',
      type: JobType.parse(readString(j, 'type')),
      coverage: Coverage.parse(readString(j, 'coverage')),
      clientName: readString(j, 'client') ?? '',
      placeName: readString(j, 'place') ?? '',
      technicianName: readString(j, 'technician') ?? '',
      closedAt: DateTime.tryParse(readString(j, 'closed_at') ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      notes: readString(j, 'notes'),
      photos: [for (final m in readMaps(j, 'photos')) ReviewPhoto.fromJson(m)],
      extras: [for (final m in readMaps(j, 'extras')) ReviewExtra.fromJson(m)],
      warranty: warranty is Map ? ReviewWarranty.fromJson(Map<String, dynamic>.from(warranty)) : null,
      plan: plan is Map ? Plan.fromJson(Map<String, dynamic>.from(plan)) : null,
    );
  }
}