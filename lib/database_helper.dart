import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'controle_financeiro.db');

    return await openDatabase(
      path,
      version: 2, // versão atualizada
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entradas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dinheiro REAL,
        pix REAL,
        data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE fiado(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        celular TEXT,
        valor REAL,
        data TEXT,
        status TEXT DEFAULT 'pendente'
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE fiado ADD COLUMN status TEXT DEFAULT 'pendente'");
    }
  }

  // ======================
  // 📊 Entradas
  // ======================
  Future<int> insertEntrada(Map<String, dynamic> entrada) async {
    final db = await database;
    return await db.insert('entradas', entrada);
  }

  Future<List<Map<String, dynamic>>> getEntradas() async {
    final db = await database;
    return await db.query('entradas', orderBy: 'data DESC');
  }

  Future<int> deleteEntrada(int id) async {
    final db = await database;
    return await db.delete('entradas', where: 'id = ?', whereArgs: [id]);
  }

  // ======================
  // 💳 Fiado
  // ======================
  Future<int> insertFiado(Map<String, dynamic> cliente) async {
    final db = await database;
    return await db.insert('fiado', cliente);
  }

  Future<List<Map<String, dynamic>>> getFiado() async {
    final db = await database;
    return await db.query('fiado', orderBy: 'data DESC');
  }

  Future<int> updateFiadoStatus(int id, String novoStatus) async {
    final db = await database;
    return await db.update('fiado', {'status': novoStatus},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteFiado(int id) async {
    final db = await database;
    return await db.delete('fiado', where: 'id = ?', whereArgs: [id]);
  }

  // ======================
  // 📈 Relatórios
  // ======================
  Future<double> getTotalEntradas(DateTime inicio, DateTime fim) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT SUM(dinheiro + pix) as total
      FROM entradas
      WHERE date(data) BETWEEN ? AND ?
    ''', [inicio.toIso8601String(), fim.toIso8601String()]);
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalFiado(String status) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT SUM(valor) as total FROM fiado WHERE status = ?
    ''', [status]);
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
