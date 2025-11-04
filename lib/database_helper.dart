import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Acesso ao banco
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa e cria banco se não existir
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'controle_financeiro.db');

    print('📦 Caminho do banco: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        print('📂 Banco aberto com sucesso!');
      },
    );
  }

  // Cria tabelas
  Future<void> _onCreate(Database db, int version) async {
    print('🚀 Criando tabelas...');

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
        data TEXT
      )
    ''');

    print('✅ Tabelas criadas com sucesso!');
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

  Future<int> deleteFiado(int id) async {
    final db = await database;
    return await db.delete('fiado', where: 'id = ?', whereArgs: [id]);
  }

  // ======================
  // 🧹 Reset (apagar tudo)
  // ======================
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'controle_financeiro.db');
    await deleteDatabase(path);
    _database = null;
    print('🧹 Banco de dados apagado e resetado.');
  }
}

