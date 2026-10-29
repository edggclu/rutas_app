import '../events/event_data.dart';
import 'extras.dart'; // ExtraEntry, RequestEntry, extrasOf, requestsOf
import 'visit_state.dart'; // VisitEvent

/// Una nota que el técnico agregó a una visita ya cerrada.
class VisitNote {
  const VisitNote({required this.text, required this.at});

  final String text;
  final DateTime at; // UTC
}

/// Todo lo que se hizo en una visita, sacado de las acciones guardadas en el teléfono.
class VisitSummary {
  const VisitSummary({
    required this.extras,
    required this.requests,
    required this.notes,
    this.closing,
    this.warranty,
  });

  final List<ExtraEntry> extras;
  final List<RequestEntry> requests;
  final List<VisitNote> notes; // en el orden en que se escribieron
  final EventData? closing; // la acción que cerró la visita (null si no está guardada aquí)
  final WarrantyDocumentedEvent? warranty; // la última garantía documentada
}

/// Arma el resumen de una visita. Las fotos y videos no van aquí: viven en `media_queue`.
VisitSummary summarizeVisit(List<VisitEvent> events, int visitId) {
  EventData? closing;
  WarrantyDocumentedEvent? warranty;
  final notes = <VisitNote>[];
  for (final e in events) {
    if (e.visitId != visitId) continue;
    final d = e.data;
    switch (d) {
      case FinishedEvent() || ContinueTomorrowEvent() || BlockedEvent() || NoAnswerConfirmedEvent():
        closing = d; // la última que cerró la visita
      case WarrantyDocumentedEvent():
        warranty = d;
      case NoteAddedEvent() when d.text.trim().isNotEmpty:
        notes.add(VisitNote(text: d.text.trim(), at: e.occurredAt));
      default:
        break; // lo demás no se resume aquí
    }
  }
  return VisitSummary(
    extras: extrasOf(events, visitId),
    requests: requestsOf(events, visitId),
    notes: notes,
    closing: closing,
    warranty: warranty,
  );
}

/// Una nota no puede ir vacía.
bool canAddNote(String text) => text.trim().isNotEmpty;
