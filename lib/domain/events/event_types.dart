/// Tipos de acción que viajan en la cola (mismos nombres que el contrato).
class EventTypes {
  EventTypes._();
  static const departureConfirmed = 'departure_confirmed';
  static const arrived = 'arrived';
  static const noAnswerReported = 'no_answer_reported';
  static const noAnswerConfirmed = 'no_answer_confirmed';
  static const finished = 'finished';
  static const continueTomorrow = 'continue_tomorrow';
  static const blocked = 'blocked';
  static const missingItems = 'missing_items';
  static const clientContacted = 'client_contacted'; // el técnico tocó llamar o WhatsApp al cliente (payload: channel)
  static const officeCalled = 'office_called'; // el técnico tocó "Llamar a la oficina"
  static const extraAdded = 'extra_added'; // el técnico registró un extra hecho en la visita
  static const requestAdded = 'request_added'; // algo para cotizar después (no se hace en esta visita)
  static const routeDelayReported = 'route_delay_reported'; // un extra va a retrasar las siguientes visitas (le llega al jefe)
    static const warrantyDocumented = 'warranty_documented'; // el técnico documento la causa y el serial de una garantía
  static const helpRequested = 'help_requested'; // el tecnico pidió ayuda al ingeniero
}