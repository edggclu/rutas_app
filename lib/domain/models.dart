import 'enums.dart';

/// Modelos del contrato `GET /api/my-day` (ver docs/contrato_api.md).
/// Se parsean a mano para no depender de generación de código en el paso 1.

class Person {
  const Person({required this.id, required this.name});
  final int id;
  final String name;

  factory Person.fromJson(Map<String, dynamic> j) =>
      Person(id: j['id'] as int, name: j['name'] as String);
}

class Contact {
  const Contact({
    required this.name,
    this.role,
    required this.phone,
    required this.authorized,
  });

  final String name;
  final String? role;
  final String phone;

  /// Solo el contacto autorizado puede pedir y aceptar extras.
  final bool authorized;

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        name: j['name'] as String,
        role: j['role'] as String?,
        phone: (j['phone'] as String?) ?? '',
        authorized: (j['authorized'] as bool?) ?? false,
      );
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
    this.estimatedKmFromOffice,
    this.accessNotes,
    this.contact,
  });

  final int id;
  final String name;
  final String address;
  final double? lat;
  final double? lng;
  final double? estimatedKmFromOffice;
  final String? accessNotes;
  final Contact? contact;

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as int,
        name: j['name'] as String,
        address: (j['address'] as String?) ?? '',
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        estimatedKmFromOffice: (j['estimated_km_from_office'] as num?)?.toDouble(),
        accessNotes: j['access_notes'] as String?,
        contact: j['contact'] == null
            ? null
            : Contact.fromJson(j['contact'] as Map<String, dynamic>),
      );
}

class Client {
  const Client({required this.id, required this.name, required this.overdue});
  final int id;
  final String name;

  /// Solo se sabe si tiene saldo vencido (sí o no). Nunca llegan montos.
  final bool overdue;

  factory Client.fromJson(Map<String, dynamic> j) => Client(
        id: j['id'] as int,
        name: j['name'] as String,
        overdue: (j['overdue'] as bool?) ?? false,
      );
}

class Job {
  const Job({
    required this.id,
    required this.folio,
    required this.type,
    required this.priority,
    required this.coverage,
    required this.description,
    this.planSummary,
    this.engineer,
    this.warrantyGuide,
  });

  final int id;
  final String folio;
  final JobType type;
  final Priority priority;
  final Coverage coverage;
  final String description;
  final String? planSummary;
  final Person? engineer;
  final String? warrantyGuide;

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        id: j['id'] as int,
        folio: j['folio'] as String,
        type: JobType.parse(j['type'] as String?),
        priority: Priority.parse(j['priority'] as String?),
        coverage: Coverage.parse(j['coverage'] as String?),
        description: (j['description'] as String?) ?? '',
        planSummary: j['plan_summary'] as String?,
        engineer: j['engineer'] == null
            ? null
            : Person.fromJson(j['engineer'] as Map<String, dynamic>),
        warrantyGuide: j['warranty_guide'] as String?,
      );
}

class Visit {
  const Visit({
    required this.id,
    required this.order,
    required this.status,
    this.result,
    this.scheduledAt,
    this.dayNumber,
    required this.responsible,
    required this.companions,
    this.arrivedAt,
    this.kmFromPrevious,
    required this.client,
    required this.place,
    required this.job,
  });

  final int id;
  final int order;
  final VisitStatus status;
  final VisitResult? result;

  /// Siempre en UTC. Se muestra con `formatClock`.
  final DateTime? scheduledAt;

  /// "Día 1", "Día 2"… sin total: el trabajo puede extenderse más de lo previsto.
  final int? dayNumber;
  final bool responsible;
  final List<Person> companions;
  final DateTime? arrivedAt;

  /// Distancia desde la visita anterior (la primera del día, desde la oficina).
  /// La calcula el servidor; se usa para la espera de "No me abren".
  final double? kmFromPrevious;
  final Client client;
  final Place place;
  final Job job;

  factory Visit.fromJson(Map<String, dynamic> j) => Visit(
        id: j['id'] as int,
        order: j['order'] as int,
        status: VisitStatus.parse(j['status'] as String?),
        result: VisitResult.parse(j['result'] as String?),
        scheduledAt: j['scheduled_at'] == null
            ? null
            : DateTime.parse(j['scheduled_at'] as String).toUtc(),
        dayNumber: j['day_number'] as int?,
        responsible: (j['responsible'] as bool?) ?? true,
        companions: ((j['companions'] as List?) ?? const [])
            .map((e) => Person.fromJson(e as Map<String, dynamic>))
            .toList(),
        arrivedAt: j['arrived_at'] == null
            ? null
            : DateTime.parse(j['arrived_at'] as String).toUtc(),
        kmFromPrevious: (j['km_from_previous'] as num?)?.toDouble(),
        client: Client.fromJson(j['client'] as Map<String, dynamic>),
        place: Place.fromJson(j['place'] as Map<String, dynamic>),
        job: Job.fromJson(j['job'] as Map<String, dynamic>),
      );
}

class DayRoute {
  const DayRoute({required this.date, required this.visits});

  final DateTime date;
  final List<Visit> visits;

  factory DayRoute.fromJson(Map<String, dynamic> j) => DayRoute(
        date: DateTime.parse(j['date'] as String),
        visits: ((j['visits'] as List?) ?? const [])
            .map((e) => Visit.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.permissions,
  });

  final int id;
  final String name;
  final String phone;
  final String role;

  /// "engineer" agrega Por validar; "dispatch" agrega Rutas (jefe de ruta).
  final List<String> permissions;

  bool get isEngineer => permissions.contains('engineer');
  bool get isDispatcher => permissions.contains('dispatch');

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        name: j['name'] as String,
        phone: (j['phone'] as String?) ?? '',
        role: (j['role'] as String?) ?? 'technician',
        permissions: ((j['permissions'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}

class Session {
  const Session({required this.token, required this.user});
  final String token;
  final AppUser user;

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        token: j['token'] as String,
        user: AppUser.fromJson(j['user'] as Map<String, dynamic>),
      );
}
