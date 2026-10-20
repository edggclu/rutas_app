import 'package:telyser_app/domain/app_settings.dart';
import 'package:telyser_app/domain/models.dart';
import 'package:telyser_app/domain/visit_state.dart';
import 'events/event_data.dart'; 

/// Kilómetros que cuentan para la espera: desde la visita anterior; si ese dato
/// falta, la distancia estimada desde la oficina que ya guarda el lugar. devuelve null si no hay ninguna de las 2
double? waitKm(Visit visit) => visit.kmFromPrevious ?? visit.place.estimatedKmFromOffice; // si es null usa el de la derecha

/// Cuanto debe esperar el tecnico: base + minutos por km*km
/// Ejemplo con valores iniciales: 5km -> 10 + 5 = 15min
Duration noAnswerWait({required double? km, required AppSettings settings}) {
  final minutes = settings.waitBaseMin + settings.waitPerKmMin * (km ?? 0); // si los kilometros son nulos solo toma el tiempo base
  return Duration (minutes: minutes.ceil()); // redondeo
}

/// Foto de dónde va el técnico en "No me abren" (qué le falta para poder irse).
class NoAnswerStatus {
  
  final double? km; // puede ser nulo
  final Duration wait; // espera total 
  final Duration remaining; // lo que falta de la espera
  final int clientContacts; // intentos de contactar al cliente hechos
  final int clientContactsNeeded; // intentos mínimos exigidos
  final int officeCalls; // llamadas a la oficina hechas
  final int officeCallsNeeded; // llamadas mínimas exigidas
  
  const NoAnswerStatus({
    required this.km, 
    required this.wait, 
    required this.remaining, 
    required this.clientContacts, 
    required this.clientContactsNeeded, 
    required this.officeCalls, 
    required this.officeCallsNeeded, 
  });

  // getters de estados
  bool get timeDone => remaining == Duration.zero;
  bool get clientOk => clientContacts >= clientContactsNeeded;
  bool get officeOk => officeCalls >= officeCallsNeeded;

  /// Las 3 condiciones juntas habilitan el deslizable 'No me atendieron'
  bool get canLeave => timeDone && clientOk && officeOk;
}

/// Calcula el estado de 'No me abren' para una visita. [now] se recibe como dato
NoAnswerStatus computeNoAnswerStatus ({
  required Visit visit,
  required List<VisitEvent> events,
  required AppSettings settings,
  required DateTime now
}) {
  final km = waitKm(visit);
  final wait = noAnswerWait(km: km, settings: settings); // calcula la espera
  final start = visit.arrivedAt ?? now;
  var remaining = start.add(wait).difference(now); // hora en que termina menos hora actual
  if (remaining.isNegative) remaining = Duration.zero;

  final clientContacts = events // cuántas veces contactó al cliente en esta visita
      .where((e) => e.visitId == visit.id && e.data is ClientContactedEvent) // eventos de esa clase
      .length; // cuántos son
  final officeCalls = events // cuántas veces llamó a la oficina en esta visita
      .where((e) => e.visitId == visit.id && e.data is OfficeCalledEvent) // eventos de esa clase
      .length; // cuántos son

  return NoAnswerStatus( // arma la foto con todo lo calculado
    km: km, // kilómetros
    wait: wait, // espera total
    remaining: remaining, // lo que falta
    clientContacts: clientContacts, // intentos con el cliente
    clientContactsNeeded: settings.minClientContacts, // mínimo exigido (parámetro)
    officeCalls: officeCalls, // llamadas a la oficina
    officeCallsNeeded: settings.minOfficeCalls, // mínimo exigido (parámetro)
  );
}