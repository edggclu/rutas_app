/// Un producto del catálogo (lo que devuelve GET /api/products/search).
class Product { // datos de un producto
  const Product({ 
    required this.id, 
    required this.name, 
    required this.unit, 
    required this.price, 
    required this.isEquipment, // true = equipo (cámara, grabador,etc ) false = material o servicio
  });

  final int id; // id del catálogo
  final String name; // nombre
  final String unit; // unidad: 'piece' o 'service'
  final num price; // precio aproximado, para dar una idea al cliente
  final bool isEquipment; // se usa para la regla del saldo vencido

  /// Texto de la unidad para mostrar: "pieza" o "servicio".
  String get unitLabel => unit == 'service' ? 'servicio' : 'pieza'; // solo existen esas dos unidades

  factory Product.fromJson(Map<String, dynamic> j) => Product( // convierte el JSON en un Product
        id: j['id'] as int, 
        name: j['name'] as String, 
        unit: (j['unit'] as String?) ?? 'piece', // si falta la unidad, se asume pieza
        price: (j['price'] as num?) ?? 0, // si falta el precio, 0
        isEquipment: (j['is_equipment'] as bool?) ?? false, // si falta, no es equipo
      );
}