import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  static Future<Database> initDB() async {
    final pathDB = await getDatabasesPath();
    final path = join(pathDB, 'tareas.db');

    return await openDatabase(
      path,
      version: 3, // ⬅️ subimos de versión
      onCreate: (db, version) async {
        await db.execute('''
  CREATE TABLE tareas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo TEXT,
    descripcion TEXT,
    completada INTEGER,
    fecha_creacion TEXT,
    fecha_limite TEXT,
    prioridad TEXT,
    recordatorio TEXT
  )
''');

      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Agregamos las columnas nuevas si no existen
          await db.execute("ALTER TABLE tareas ADD COLUMN fecha_creacion TEXT");
          await db.execute("ALTER TABLE tareas ADD COLUMN fecha_limite TEXT");
        }
 if (oldVersion < 3) {
      await db.execute("ALTER TABLE tareas ADD COLUMN prioridad TEXT DEFAULT 'media'");
      await db.execute("ALTER TABLE tareas ADD COLUMN recordatorio TEXT");
        }
      },
    );
  }
}