import 'package:flutter/material.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../site/site_screen.dart';
import '../visit_summary/visit_summary_screen.dart';
import 'visit_detail_loader.dart';

/// Abre la pantalla que corresponde a la visita según su estado: el resumen si ya se cerró, la
/// pantalla de trabajo si está En sitio y la tarjeta de la visita en los demás casos.
void openVisit(BuildContext context, Visit v) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => switch (v.status) {
        VisitStatus.done => VisitSummaryScreen(visitId: v.id),
        VisitStatus.onSite => SiteScreen(visitId: v.id),
        VisitStatus.pending || VisitStatus.enRoute => VisitDetailLoader(visitId: v.id),
      },
    ),
  );
}
