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
}