import '../models/enums.dart';
import '../models/models.dart';

enum TechStateKind { enRoute, onSite, free }

/// Estado del técnico: nadie lo marca, se calcula del estado de sus visitas.
class TechnicianState {
  const TechnicianState(this.kind, [this.placeName]);
  final TechStateKind kind;
  final String? placeName;

  String get label {
    switch (kind) {
      case TechStateKind.enRoute:
        return 'En camino a $placeName';
      case TechStateKind.onSite:
        return 'En sitio en $placeName';
      case TechStateKind.free:
        return 'Libre';
    }
  }
}

TechnicianState computeTechnicianState(List<Visit> visits) =>
    technicianStateOf([for (final v in visits) (status: v.status, client: v.client.name)]);

/// El estado de un técnico a partir de sus visitas (estado y nombre del cliente de cada una).
/// Lo usan la pantalla del técnico y la del jefe de ruta.
TechnicianState technicianStateOf(Iterable<({VisitStatus status, String client})> stops) {
  for (final s in stops) {
    if (s.status == VisitStatus.onSite) return TechnicianState(TechStateKind.onSite, s.client);
  }
  for (final s in stops) {
    if (s.status == VisitStatus.enRoute) return TechnicianState(TechStateKind.enRoute, s.client);
  }
  return const TechnicianState(TechStateKind.free);
}
