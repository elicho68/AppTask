import '../models/tarea.dart';
import 'db_service.dart';

class TareaDAO {
static Future<Tarea> insertarTarea(Tarea tarea) async {
  final db = await DBService.getDatabase();
  final id = await db.insert(
    'tareas',
    tarea.toMap(includeId: false), // 👈 importante
  );
  return tarea.copiarCon(id: id); // devuelvo la tarea con ID real
}

  static Future<List<Tarea>> obtenerTareas() async {
    final db = await DBService.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('tareas');

    return List.generate(maps.length, (i) {
      return Tarea.fromMap(maps[i]);
    });
  }

static Future<void> actualizarTarea(Tarea tarea) async {
  final db = await DBService.getDatabase();
  await db.update(
    'tareas',
    tarea.toMap(includeId: true), // 👈 ID sí necesario al actualizar
    where: 'id = ?',
    whereArgs: [tarea.id],
  );
}



  static Future<void> eliminarTarea(int id) async {
    final db = await DBService.getDatabase();
    await db.delete(
      'tareas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
