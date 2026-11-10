import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// La carpeta de un usuario dentro de los documentos de la app, relativa: `users/<id>`. Ahí viven
/// su base local (la cola, la ruta guardada, los parámetros) y sus fotos y videos, para que dos
/// personas que usan el mismo teléfono nunca vean ni envíen lo de la otra.
String userFolderName(int userId) => p.join('users', '$userId');

/// El nombre del archivo de la base dentro de la carpeta del usuario.
const databaseFileName = 'telyser.sqlite';

/// La carpeta del usuario en el teléfono (la crea si no existe).
Future<Directory> userDirectory(int userId) async {
  final root = await getApplicationDocumentsDirectory();
  return Directory(p.join(root.path, userFolderName(userId))).create(recursive: true);
}
