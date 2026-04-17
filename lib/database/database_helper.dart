import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/agendamento.dart';
import '../models/log_operacao.dart';
import '../models/sala.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'coworking.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = WAL');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sala (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS uq_sala_nome
      ON sala (nome COLLATE NOCASE)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS agendamento (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        sala_id INTEGER NOT NULL,
        inicio  TEXT NOT NULL,
        fim     TEXT NOT NULL,
        CONSTRAINT fk_agendamento_sala
          FOREIGN KEY (sala_id) REFERENCES sala (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS log_operacao (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_tabela   TEXT NOT NULL,
        tipo_operacao TEXT NOT NULL,
        data_hora     TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_sala_before_insert
      BEFORE INSERT ON sala
      BEGIN
        SELECT CASE
          WHEN NEW.nome IS NULL OR TRIM(NEW.nome) = ''
          THEN RAISE(ABORT, 'O nome da sala é obrigatório.')
        END;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_sala_log_insert
      AFTER INSERT ON sala
      BEGIN
        INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
        VALUES (
          'sala',
          'INSERT',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        );
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_sala_before_update
      BEFORE UPDATE ON sala
      BEGIN
        SELECT CASE
          WHEN NEW.nome IS NULL OR TRIM(NEW.nome) = ''
          THEN RAISE(ABORT, 'O nome da sala é obrigatório.')
        END;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_sala_log_update
      AFTER UPDATE ON sala
      BEGIN
        INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
        VALUES (
          'sala',
          'UPDATE',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        );
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_sala_before_delete
      BEFORE DELETE ON sala
      BEGIN
        SELECT CASE
          WHEN EXISTS (
            SELECT 1
            FROM agendamento
            WHERE sala_id = OLD.id
              AND inicio > STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
          )
          THEN RAISE(
            ABORT,
            'Não é possível excluir uma sala com agendamentos futuros.'
          )
        END;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_sala_log_delete
      AFTER DELETE ON sala
      BEGIN
        INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
        VALUES (
          'sala',
          'DELETE',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        );
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_agendamento_before_insert
      BEFORE INSERT ON agendamento
      BEGIN
        SELECT CASE
          WHEN NEW.sala_id IS NULL
          THEN RAISE(ABORT, 'A sala é obrigatória.')
          WHEN NEW.inicio IS NULL OR TRIM(NEW.inicio) = ''
          THEN RAISE(ABORT, 'A data/hora de início é obrigatória.')
          WHEN NEW.fim IS NULL OR TRIM(NEW.fim) = ''
          THEN RAISE(ABORT, 'A data/hora de fim é obrigatória.')
          WHEN NEW.fim <= NEW.inicio
          THEN RAISE(ABORT, 'A data/hora de fim deve ser maior que a de início.')
          WHEN EXISTS (
            SELECT 1
            FROM agendamento
            WHERE sala_id = NEW.sala_id
              AND NEW.inicio < fim
              AND NEW.fim > inicio
          )
          THEN RAISE(
            ABORT,
            'Já existe um agendamento nesse horário para a sala selecionada.'
          )
        END;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_insert
      AFTER INSERT ON agendamento
      BEGIN
        INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
        VALUES (
          'agendamento',
          'INSERT',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        );
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_agendamento_before_update
      BEFORE UPDATE ON agendamento
      BEGIN
        SELECT CASE
          WHEN NEW.sala_id IS NULL
          THEN RAISE(ABORT, 'A sala é obrigatória.')
          WHEN NEW.inicio IS NULL OR TRIM(NEW.inicio) = ''
          THEN RAISE(ABORT, 'A data/hora de início é obrigatória.')
          WHEN NEW.fim IS NULL OR TRIM(NEW.fim) = ''
          THEN RAISE(ABORT, 'A data/hora de fim é obrigatória.')
          WHEN NEW.fim <= NEW.inicio
          THEN RAISE(ABORT, 'A data/hora de fim deve ser maior que a de início.')
          WHEN EXISTS (
            SELECT 1
            FROM agendamento
            WHERE sala_id = NEW.sala_id
              AND id != NEW.id
              AND NEW.inicio < fim
              AND NEW.fim > inicio
          )
          THEN RAISE(
            ABORT,
            'Já existe um agendamento nesse horário para a sala selecionada.'
          )
        END;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_update
      AFTER UPDATE ON agendamento
      BEGIN
        INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
        VALUES (
          'agendamento',
          'UPDATE',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        );
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_delete
      AFTER DELETE ON agendamento
      BEGIN
        INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
        VALUES (
          'agendamento',
          'DELETE',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        );
      END
    ''');
  }

  Future<List<Sala>> getSalas() async {
    final db = await database;
    final rows = await db.query('sala', orderBy: 'nome COLLATE NOCASE');
    return rows.map(Sala.fromMap).toList();
  }

  Future<int> insertSala(Sala sala) async {
    final db = await database;
    return db.insert('sala', sala.toMap()..remove('id'));
  }

  Future<int> updateSala(Sala sala) async {
    final db = await database;
    return db.update('sala', sala.toMap(), where: 'id = ?', whereArgs: [sala.id]);
  }

  Future<int> deleteSala(int id) async {
    final db = await database;
    return db.delete('sala', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Agendamento>> getAgendamentos() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.*, s.nome AS sala_nome
      FROM agendamento a
      JOIN sala s ON s.id = a.sala_id
      ORDER BY a.inicio
    ''');

    return rows.map((row) {
      final sala = Sala(
        id: row['sala_id'] as int,
        nome: row['sala_nome'] as String,
      );
      return Agendamento.fromMap(row, sala: sala);
    }).toList();
  }

  Future<int> insertAgendamento(Agendamento agendamento) async {
    final db = await database;
    return db.insert('agendamento', agendamento.toMap()..remove('id'));
  }

  Future<int> updateAgendamento(Agendamento agendamento) async {
    final db = await database;
    return db.update(
      'agendamento',
      agendamento.toMap(),
      where: 'id = ?',
      whereArgs: [agendamento.id],
    );
  }

  Future<int> deleteAgendamento(int id) async {
    final db = await database;
    return db.delete('agendamento', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LogOperacao>> getLogs() async {
    final db = await database;
    final rows = await db.query('log_operacao', orderBy: 'id DESC', limit: 200);
    return rows.map(LogOperacao.fromMap).toList();
  }
}
