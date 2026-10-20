import 'payload.dart'; // lectores y lookup

/// De dónde salió el material del extra.
enum ExtraSource { // opciones del formulario
  jobReserved('job_reserved', 'Apartado del trabajo'), // material que Axel separó para este trabajo
  ownStock('own_stock', 'Mi material'), // lo que el técnico trae en su camioneta (genera reposición)
  boughtOnRoute('bought_on_route', 'Compra en ruta'); // lo compró en el camino

  const ExtraSource(this.code, this.label); // constructor de cada opción
  final String code; // texto que viaja al servidor
  final String label; // texto que ve el técnico
  static ExtraSource? tryFromCode(String? c) => lookup(values, c, (v) => v.code); // null si no existe
}

/// Por qué se hizo el extra.
enum ExtraReason { // opciones del formulario
  clientAsked('client_asked', 'Lo pidió el cliente'), // el cliente lo pidió
  siteRequired('site_required', 'Lo exigió el sitio'); // el sitio lo exigía

  const ExtraReason(this.code, this.label); // constructor de cada opción
  final String code; // texto que viaja al servidor
  final String label; // texto que ve el técnico
  static ExtraReason? tryFromCode(String? c) => lookup(values, c, (v) => v.code); // null si no existe
}

/// Qué pasa con un extra al guardarlo.
enum ExtraOutcome { // los tres resultados posibles
  register, // se hace y se anota
  laterOtherPerson, // lo pidió otra persona: no se hace, queda como solicitud
  laterCreditHold, // cliente con saldo vencido y es equipo: no se hace, queda como solicitud
}

/// De dónde viene una solicitud para después.
enum RequestOrigin { // tres orígenes
  otherPerson('other_person'), // un extra que pidió otra persona
  creditHold('credit_hold'), // un extra de equipo a un cliente con saldo vencido
  cannotDoNow('cannot_do_now'); // la creó el técnico con "Solicitud después"

  const RequestOrigin(this.code); // constructor de cada opción
  final String code; // texto que viaja al servidor
  static RequestOrigin? tryFromCode(String? c) => lookup(values, c, (v) => v.code); // null si no existe
}

/// Lo que el técnico llenó en el formulario "Agregar extra".
class ExtraDraft { // un borrador del extra
  const ExtraDraft({ // constructor
    required this.name, // qué es
    this.productId, // id del catálogo (null si lo escribió a mano)
    required this.quantity, // cuánto
    this.unit, // 'piece' o 'service' (null si lo escribió a mano)
    required this.source, // de dónde salió
    required this.reason, // por qué
    required this.requestedByAuthorized, // true = lo pidió el contacto autorizado
    this.isEquipment = true, // si es equipo; sin catálogo se asume que sí (lado seguro)
    this.notInstalled = false, // true = algo que NO se instaló
    this.delayMinutes, // minutos que retrasará las siguientes visitas (null = no retrasa)
  });

  final String name; // nombre o descripción
  final int? productId; // id del catálogo
  final num quantity; // cantidad
  final String? unit; // unidad del producto
  final ExtraSource source; // origen del material
  final ExtraReason reason; // motivo
  final bool requestedByAuthorized; // quién lo pidió
  final bool isEquipment; // ¿es equipo?
  final bool notInstalled; // ¿es una nota de "no se instaló"?
  final int? delayMinutes; // retraso estimado
}

/// Los datos de un extra tal como se guardan en la cola (los comparten
/// `extra_added` y las solicitudes que nacen de un extra).
class ExtraItem { // el renglón del extra
  const ExtraItem({ // constructor
    required this.name, // nombre
    this.productId, // id del catálogo
    required this.quantity, // cantidad
    this.unit, // unidad
    required this.source, // origen
    required this.reason, // motivo
    required this.requestedByAuthorized, // ¿lo pidió el contacto autorizado?
    this.requesterName, // nombre del contacto, si fue él
    required this.notInstalled, // ¿es "no se instaló"?
  });

  final String name; // nombre
  final int? productId; // id del catálogo
  final num quantity; // cantidad
  final String? unit; // unidad
  final ExtraSource source; // origen
  final ExtraReason reason; // motivo
  final bool requestedByAuthorized; // quién lo pidió
  final String? requesterName; // nombre de quien lo pidió
  final bool notInstalled; // ¿no se instaló?

  Map<String, dynamic> toPayload() => { // tal como viaja al servidor (igual que antes)
        'name': name, // nombre
        'product_id': productId, // id del catálogo
        'quantity': quantity, // cantidad
        'unit': unit, // unidad
        'source': source.code, // de dónde salió
        'reason': reason.code, // por qué
        'requested_by': requestedByAuthorized ? 'authorized_contact' : 'other', // quién lo pidió
        'requester_name': requesterName, // nombre del contacto
        'not_installed': notInstalled, // ¿no se instaló?
      };

  factory ExtraItem.fromPayload(Map<String, dynamic> p) => ExtraItem( // lo reconstruye desde el mapa guardado
        name: readString(p, 'name') ?? '', // nombre (vacío si falta)
        productId: readInt(p, 'product_id'), // id del catálogo
        quantity: readNum(p, 'quantity') ?? 1, // cantidad (1 si falta)
        unit: readString(p, 'unit'), // unidad
        source: ExtraSource.tryFromCode(readString(p, 'source')) ?? ExtraSource.ownStock, // origen (valor por defecto si falta)
        reason: ExtraReason.tryFromCode(readString(p, 'reason')) ?? ExtraReason.clientAsked, // motivo (valor por defecto si falta)
        requestedByAuthorized: readString(p, 'requested_by') == 'authorized_contact', // quién lo pidió
        requesterName: readString(p, 'requester_name'), // nombre del contacto
        notInstalled: readBool(p, 'not_installed') ?? false, // ¿no se instaló?
      );
}