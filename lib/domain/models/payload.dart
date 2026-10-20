/// Lectores de datos sueltos (el mapa que viene de la base). Si el dato falta o
/// tiene otro tipo, devuelven null en vez de romper la app.
String? readString(Map<String, dynamic> p, String key) { // lee un texto
  final v = p[key]; // el valor guardado
  return v is String ? v : null; // solo si de verdad es texto
}

num? readNum(Map<String, dynamic> p, String key) { // lee un número (entero o decimal)
  final v = p[key]; // el valor guardado
  return v is num ? v : null; // solo si de verdad es número
}

int? readInt(Map<String, dynamic> p, String key) { // lee un entero
  final v = p[key]; // el valor guardado
  return v is int ? v : null; // solo si de verdad es entero
}

bool? readBool(Map<String, dynamic> p, String key) { // lee un sí/no
  final v = p[key]; // el valor guardado
  return v is bool ? v : null; // solo si de verdad es booleano
}

/// Lee una lista de objetos (ej. los renglones faltantes).
List<Map<String, dynamic>> readMaps(Map<String, dynamic> p, String key) { // devuelve lista vacía si no hay
  final v = p[key]; // el valor guardado
  if (v is! List) return const []; // si no es lista, vacía
  return [for (final i in v) if (i is Map) Map<String, dynamic>.from(i)]; // cada elemento que sea objeto
}

/// Busca un valor de enum por su código de texto. null si no existe.
T? lookup<T>(Iterable<T> values, String? code, String Function(T) codeOf) { // values = todos los valores del enum
  for (final v in values) { // recorre cada valor
    if (codeOf(v) == code) return v; // el primero cuyo código coincide
  }
  return null; // ninguno coincide
}