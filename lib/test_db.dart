// lib/test_db.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Inicializa FFI (necessário para desktop)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = await databaseFactory.getDatabasesPath();
  final path = join(dbPath, 'controle_financeiro.db');

  print('📂 Caminho do banco: $path');

  // Abre/cria banco
  final db = await databaseFactory.openDatabase(path);

  // Lista tabelas
  final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
  print('📋 Tabelas encontradas:');
  for (var t in tables) {
    print(' - ${t['name']}');
  }

  // Exemplo: listar entradas e fiado (se existirem)
  try {
    final entradas = await db.rawQuery('SELECT * FROM entradas;');
    print('\n💾 Entradas:');
    for (var r in entradas) print(r);
  } catch (e) {
    print('\n⚠️ Tabela entradas não encontrada ou erro: $e');
  }

  try {
    final fiado = await db.rawQuery('SELECT * FROM fiado;');
    print('\n💾 Fiado:');
    for (var r in fiado) print(r);
  } catch (e) {
    print('\n⚠️ Tabela fiado não encontrada ou erro: $e');
  }

  await db.close();
}
