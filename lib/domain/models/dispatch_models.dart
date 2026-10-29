import 'enums.dart';
import 'payload.dart';

/// Qué le pide una decisión al jefe de ruta. Un tipo que la app no conoce se lee como [other].
enum DecisionKind {
  urgent('urgent'),
  blocked('blocked'),
  continueProposed('continue_proposed'),
  returned('returned'),
  routeDelay('route_delay'),
  outOfOrder('out_of_order'),
  other('');

  const DecisionKind(this.code);
  final String code;

  static DecisionKind parse(String? s) =>
      values.firstWhere((k) => k.code.isNotEmpty && k.code == s, orElse: () => DecisionKind.other);
}

/// Algo que el jefe de ruta debe resolver hoy. El servidor ya escribe el título y el detalle.
class Decision {
  const Decision({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.createdAt,
    this.jobFolio,
  });

  final int id;
  final DecisionKind kind;
  final String title;
  final String detail;
  final String? jobFolio;
  final DateTime createdAt; // UTC

  factory Decision.fromJson(Map<String, dynamic> j) => Decision(
        id: readInt(j, 'id') ?? 0,
        kind: DecisionKind.parse(readString(j, 'kind')),
        title: readString(j, 'title') ?? '',
        detail: readString(j, 'detail') ?? '',
        jobFolio: readString(j, 'job_folio'),
        createdAt: DateTime.tryParse(readString(j, 'created_at') ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

/// Las urgencias van arriba; lo demás, de lo más nuevo a lo más viejo.
List<Decision> sortDecisions(Iterable<Decision> list) {
  final out = list.toList();
  out.sort((a, b) {
    final aUrgent = a.kind == DecisionKind.urgent ? 0 : 1;
    final bUrgent = b.kind == DecisionKind.urgent ? 0 : 1;
    return aUrgent != bUrgent ? aUrgent.compareTo(bUrgent) : b.createdAt.compareTo(a.createdAt);
  });
  return out;
}

/// Una visita en la ruta de un técnico, con lo justo para que el jefe la vea.
class DispatchVisit {
  const DispatchVisit({
    required this.id,
    required this.status,
    required this.clientName,
    required this.placeName,
    this.result,
    this.dayNumber,
    this.scheduledAt,
  });

  final int id;
  final VisitStatus status;
  final VisitResult? result;
  final int? dayNumber;
  final String clientName;
  final String placeName;
  final DateTime? scheduledAt; // UTC

  factory DispatchVisit.fromJson(Map<String, dynamic> j) => DispatchVisit(
        id: readInt(j, 'id') ?? 0,
        status: VisitStatus.parse(readString(j, 'status')),
        result: VisitResult.parse(readString(j, 'result')),
        dayNumber: readInt(j, 'day_number'),
        clientName: readString(j, 'client') ?? '',
        placeName: readString(j, 'place') ?? '',
        scheduledAt: DateTime.tryParse(readString(j, 'scheduled_at') ?? '')?.toUtc(),
      );
}

/// La ruta de un técnico en un día.
class TechnicianRoute {
  const TechnicianRoute({required this.id, required this.name, required this.visits});

  final int id;
  final String name;
  final List<DispatchVisit> visits; // en el orden que decidió el técnico

  factory TechnicianRoute.fromJson(Map<String, dynamic> j) => TechnicianRoute(
        id: readInt(j, 'id') ?? 0,
        name: readString(j, 'name') ?? '',
        visits: [for (final m in readMaps(j, 'visits')) DispatchVisit.fromJson(m)],
      );
}

/// Las cinco luces del semáforo de un trabajo por asignar.
enum Light {
  confirmed('client_confirmed', 'Cliente confirmado'),
  deposit('deposit_paid', 'Anticipo pagado'),
  balance('balance', 'Sin adeudo'),
  material('material_ready', 'Material listo'),
  access('access', 'Acceso');

  const Light(this.code, this.label);
  final String code;
  final String label;
}

enum LightState {
  ok,
  warning,
  blocked;

  /// Un valor desconocido se lee como "pendiente" (ámbar): ni se da por bueno ni bloquea.
  static LightState parse(String? s) => switch (s) {
        'ok' => LightState.ok,
        'blocked' => LightState.blocked,
        _ => LightState.warning,
      };
}

/// Un trabajo aprobado que todavía no tiene visita.
class UnassignedJob {
  const UnassignedJob({
    required this.id,
    required this.folio,
    required this.type,
    required this.priority,
    required this.clientName,
    required this.placeName,
    required this.lights,
    required this.canSchedule,
  });

  final int id;
  final String folio;
  final JobType type;
  final Priority priority;
  final String clientName;
  final String placeName;
  final Map<Light, LightState> lights;
  final bool canSchedule; // el servidor dice si ya se puede programar

  factory UnassignedJob.fromJson(Map<String, dynamic> j) {
    final raw = j['lights'];
    final lights = {
      for (final l in Light.values) l: LightState.parse(raw is Map ? raw[l.code] as String? : null),
    };
    return UnassignedJob(
      id: readInt(j, 'id') ?? 0,
      folio: readString(j, 'folio') ?? '',
      type: JobType.parse(readString(j, 'type')),
      priority: Priority.parse(readString(j, 'priority')),
      clientName: readString(j, 'client') ?? '',
      placeName: readString(j, 'place') ?? '',
      lights: lights,
      // Si el servidor no lo dice, solo se bloquea cuando alguna luz está en rojo.
      canSchedule: readBool(j, 'can_schedule') ?? !lights.values.contains(LightState.blocked),
    );
  }
}

/// Todo lo que muestra la pantalla del jefe de ruta.
class DispatchBoard {
  const DispatchBoard({
    required this.decisions,
    required this.today,
    required this.tomorrow,
    required this.unassigned,
  });

  final List<Decision> decisions;
  final List<TechnicianRoute> today;
  final List<TechnicianRoute> tomorrow;
  final List<UnassignedJob> unassigned;

  factory DispatchBoard.fromJson(Map<String, dynamic> j) {
    List<TechnicianRoute> routes(String key) {
      final section = j[key];
      return section is Map<String, dynamic>
          ? [for (final m in readMaps(section, 'technicians')) TechnicianRoute.fromJson(m)]
          : const [];
    }

    return DispatchBoard(
      decisions: sortDecisions([for (final m in readMaps(j, 'decisions')) Decision.fromJson(m)]),
      today: routes('today'),
      tomorrow: routes('tomorrow'),
      unassigned: [for (final m in readMaps(j, 'unassigned')) UnassignedJob.fromJson(m)],
    );
  }
}
