import 'enums.dart';
import 'models.dart';

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

TechnicianState computeTechnicianState(List<Visit> visits) {
  for (final v in visits) {
    if (v.status == VisitStatus.onSite) {
      return TechnicianState(TechStateKind.onSite, v.client.name);
    }
  }
  for (final v in visits) {
    if (v.status == VisitStatus.enRoute) {
      return TechnicianState(TechStateKind.enRoute, v.client.name);
    }
  }
  return const TechnicianState(TechStateKind.free);
}
