import 'package:telyser_app/domain/format.dart';

import 'enums.dart';

/// Modelos del contrato `GET /api/my-day` (ver docs/contrato_api.md).
/// Se parsean a mano para no depender de generación de código en el paso 1.

class Person { // una persona: ingeniero o acompañante
  const Person({required this.id, required this.name, this.phone}); // el telefono es opcional
  final int id; // id
  final String name; // nombre
  final String? phone; // teléfono (se usa para pedir ayuda por WhatsApp)

  factory Person.fromJson(Map<String, dynamic> j) => Person( // convierte el JSON
      id: j['id'] as int, // id
      name: j['name'] as String, // nombre
      phone: j['phone'] as String?); // teléfono, o null si no viene
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
    this.plan
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
  final Plan? plan;

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
        plan: j['plan'] == null // si el trabajo no tiene plan
            ? null // queda vacío
            : Plan.fromJson(j['plan'] as Map<String, dynamic>), // si no, lo convierte
      );
}

class ChecklistItem {

  final int id;
  final ChecklistKind kind;
  final String text;
  final num? quantity;

  /// Producto del catálogo, si el renglón viene de uno (la herramienta no).
  final int? productId;

  const ChecklistItem({
    required this.id,
    required this.kind,
    required this.text,
    this.quantity,
    this.productId
  });
  /// "×8", "×120" o "" si no hay cantidad. Los enteros se muestran sin ".0".
  String get quantityLabel {
    final q = quantity;
    if (q== null) return '';
    return 'x${formatNumber(q)}';
    // return (q==null) ? '' : 'x${q% 1 == 0 ? q.toInt() : q}';
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
    id: j['id'] as int, 
    kind: ChecklistKind.parse(j['kind'] as String?),
    text: j['text'] as String,
    quantity: j['quantity'] as num?,
    productId: j['product_id'] as int?
  );

  ChecklistItem copyWith({String? text, num? quantity, bool clearQuantity = false}) => ChecklistItem(
        id: id,
        kind: kind,
        text: text ?? this.text,
        quantity: clearQuantity ? null : (quantity ?? this.quantity),
        productId: productId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name, // 'material' o 'tool'
        'text': text,
        'quantity': quantity,
        'product_id': productId,
      };
}

/// Lista de material y herramienta que el técnico revisa antes de salir.
class Checklist {
  final ChecklistSource source;
  final List<ChecklistItem> items;
  const Checklist({required this.source, required this.items});

  /// Sin lista: el técnico lleva su material de siempre.
  static const empty = Checklist(source: ChecklistSource.none, items: []);

  // Listas de materiales y herramientas
  List<ChecklistItem> get materials =>
    items.where((item) => item.kind == ChecklistKind.material).toList();
  List<ChecklistItem> get tools =>
    items.where((item) => item.kind == ChecklistKind.tool).toList();

  factory Checklist.fromJson(Map<String, dynamic> j) => Checklist(
    source: ChecklistSource.parse(j['source'] as String?), 
    items: ((j['items'] as List?) ?? const [])
      .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
      .toList()
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
    this.checklist = Checklist.empty
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

  // Lista de salida, vacia si el servidor no manda ninguna
  final Checklist checklist;

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
        checklist: j['checklist'] == null 
          ? Checklist.empty 
          : Checklist.fromJson(j['checklist'] as Map<String, dynamic>)
      );

      Visit copyWith ({
        VisitStatus? status,
        VisitResult? result,
        DateTime? arrivedAt,
      }) => 
          Visit(
            id: id, 
            order: order, 
            status: status ?? this.status, 
            result: result ?? this.result,
            scheduledAt: scheduledAt,
            dayNumber: dayNumber,
            responsible: responsible, 
            companions: companions, 
            arrivedAt: arrivedAt ?? this.arrivedAt,
            kmFromPrevious: kmFromPrevious,
            client: client, 
            place: place, 
            job: job,
            checklist: checklist
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

/// Un punto numerado sobre el croquis (C1, C2...).
class SketchPin { // dato de un pin
  const SketchPin({ // constructor
    required this.id, // id del pin
    required this.label, // texto que se ve sobre el pin ("C1", "NVR")
    required this.x, // posición horizontal, de 0 (izquierda) a 1 (derecha)
    required this.y, // posición vertical, de 0 (arriba) a 1 (abajo)
    this.note, // nota del ingeniero para ese punto
  });

  final int id; // id
  final String label; // etiqueta
  final double x; // posición relativa horizontal
  final double y; // posición relativa vertical
  final String? note; // nota (puede faltar)

  factory SketchPin.fromJson(Map<String, dynamic> j) => SketchPin( // convierte el JSON
        id: j['id'] as int, // id
        label: j['label'] as String, // etiqueta
        x: (j['x'] as num).toDouble(), // posición horizontal
        y: (j['y'] as num).toDouble(), // posición vertical
        note: j['note'] as String?, // nota
      );

  SketchPin copyWith({String? label, double? x, double? y, String? note}) => SketchPin( // copia con cambios
        id: id,
        label: label ?? this.label,
        x: x ?? this.x,
        y: y ?? this.y,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'x': x, 'y': y, 'note': note};
}

/// El croquis: una imagen con sus pines.
class Sketch { // dato del croquis
  const Sketch({required this.image, required this.aspectRatio, required this.pins}); // constructor

  final String image; // ruta de la imagen (en prueba un asset; con la API real, una URL)
  final double aspectRatio; // ancho / alto de la imagen (sirve para colocar los pines sin leer la imagen)
  final List<SketchPin> pins; // los pines

  factory Sketch.fromJson(Map<String, dynamic> j) => Sketch( // convierte el JSON
        image: j['image'] as String, // imagen
        aspectRatio: (j['aspect_ratio'] as num?)?.toDouble() ?? 1.5, // proporción (1.5 si falta)
        pins: ((j['pins'] as List?) ?? const []) // lista de pines (vacía si falta)
            .map((e) => SketchPin.fromJson(e as Map<String, dynamic>)) // cada pin
            .toList(), // junta todo en una lista
      );

  Sketch withPins(List<SketchPin> newPins) => Sketch(image: image, aspectRatio: aspectRatio, pins: newPins);

  Map<String, dynamic> toJson() => {
        'image': image,
        'aspect_ratio': aspectRatio,
        'pins': [for (final p in pins) p.toJson()],
      };
}

/// El plan que define el ingeniero después del levantamiento.
class Plan { // dato del plan
  const Plan({required this.items, this.notes, this.sketch}); // constructor

  final List<ChecklistItem> items; // renglones de material y herramienta (el mismo formato que la lista de salida)
  final String? notes; // notas del ingeniero
  final Sketch? sketch; // croquis con pines (puede faltar)

  List<ChecklistItem> get materials => // solo el material
      items.where((i) => i.kind == ChecklistKind.material).toList(); // los renglones de tipo material
  List<ChecklistItem> get tools => // solo la herramienta
      items.where((i) => i.kind == ChecklistKind.tool).toList(); // los renglones de tipo herramienta

  factory Plan.fromJson(Map<String, dynamic> j) => Plan( // convierte el JSON
        items: ((j['items'] as List?) ?? const []) // renglones (vacío si falta)
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>)) // cada renglón
            .toList(), // junta todo en una lista
        notes: j['notes'] as String?, // notas
        sketch: j['sketch'] == null // si no hay croquis
            ? null // queda vacío
            : Sketch.fromJson(j['sketch'] as Map<String, dynamic>), // si no, lo convierte
      );

  Map<String, dynamic> toJson() => {
        'notes': notes,
        'items': [for (final i in items) i.toJson()],
        'sketch': sketch?.toJson(),
      };
}