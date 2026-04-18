import 'package:flutter/foundation.dart';
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
    final path = kIsWeb
        ? 'coworking.db'
        : join(await getDatabasesPath(), 'coworking.db');

    return openDatabase(
      path,
      version: 7,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        if (!kIsWeb) {
          await db.execute('PRAGMA journal_mode = WAL');
        }
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
        data_hora     TEXT NOT NULL,
        descricao     TEXT
      )
    ''');

    await _createAgendamentoEncerramentoLogTable(db);

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

    await db.execute('DROP TRIGGER IF EXISTS trg_agendamento_before_update');
    await db.execute('DROP TRIGGER IF EXISTS trg_agendamento_before_delete');
    await _createAgendamentoMutabilityGuards(db);
    await _recreateSalaDeleteGuardTrigger(db);
    await _ensureLogDescricaoColumn(db);
    await _recreateOperationLogTriggers(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TRIGGER IF EXISTS trg_agendamento_before_update');
      await db.execute('DROP TRIGGER IF EXISTS trg_agendamento_before_delete');
      await _createAgendamentoMutabilityGuards(db);
    }
    if (oldVersion < 3) {
      await _createAgendamentoEncerramentoLogTable(db);
    }
    if (oldVersion < 4) {
      await _ensureLogDescricaoColumn(db);
      await _recreateOperationLogTriggers(db);
    }
    if (oldVersion < 5) {
      await _recreateSalaDeleteGuardTrigger(db);
    }
    if (oldVersion < 6) {
      await db.execute('DROP TRIGGER IF EXISTS trg_agendamento_before_update');
      await db.execute('DROP TRIGGER IF EXISTS trg_agendamento_before_delete');
      await _createAgendamentoMutabilityGuards(db);
    }
    if (oldVersion < 7) {
      await _recreateSalaDeleteGuardTrigger(db);
    }
  }

  Future<void> _createAgendamentoMutabilityGuards(Database db) async {
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_agendamento_before_update
      BEFORE UPDATE ON agendamento
      BEGIN
        SELECT CASE
          WHEN OLD.inicio <= STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
          THEN RAISE(ABORT, 'Nao e possivel alterar uma reuniao apos o inicio.')
          WHEN NEW.sala_id IS NULL
          THEN RAISE(ABORT, 'A sala e obrigatoria.')
          WHEN NEW.inicio IS NULL OR TRIM(NEW.inicio) = ''
          THEN RAISE(ABORT, 'A data/hora de inicio e obrigatoria.')
          WHEN NEW.fim IS NULL OR TRIM(NEW.fim) = ''
          THEN RAISE(ABORT, 'A data/hora de fim e obrigatoria.')
          WHEN NEW.fim <= NEW.inicio
          THEN RAISE(ABORT, 'A data/hora de fim deve ser maior que a de inicio.')
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
            'Ja existe um agendamento nesse horario para a sala selecionada.'
          )
        END;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_agendamento_before_delete
      BEFORE DELETE ON agendamento
      BEGIN
        SELECT CASE
          WHEN OLD.fim > STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
          THEN RAISE(ABORT, 'Nao e possivel excluir uma reuniao em andamento ou futura.')
        END;
      END
    ''');
  }

  Future<void> _recreateSalaDeleteGuardTrigger(Database db) async {
    await db.execute('DROP TRIGGER IF EXISTS trg_sala_before_delete');
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
            'Nao e possivel excluir uma sala com agendamentos futuros.'
          )
          WHEN EXISTS (
            SELECT 1
            FROM agendamento
            WHERE sala_id = OLD.id
              AND inicio <= STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
              AND fim > STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
          )
          THEN RAISE(
            ABORT,
            'Nao e possivel excluir uma sala com reuniao em andamento.'
          )
        END;
      END
    ''');
  }

  Future<void> _createAgendamentoEncerramentoLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS agendamento_encerramento_log (
        agendamento_id INTEGER PRIMARY KEY,
        data_hora      TEXT NOT NULL,
        CONSTRAINT fk_encerramento_agendamento
          FOREIGN KEY (agendamento_id) REFERENCES agendamento (id)
      )
    ''');
  }

  Future<void> _ensureLogDescricaoColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(log_operacao)');
    final hasDescricao = columns.any(
      (row) => (row['name'] as String?)?.toLowerCase() == 'descricao',
    );
    if (!hasDescricao) {
      await db.execute('ALTER TABLE log_operacao ADD COLUMN descricao TEXT');
    }
  }

  Future<void> _recreateOperationLogTriggers(Database db) async {
    await db.execute('DROP TRIGGER IF EXISTS trg_sala_log_insert');
    await db.execute('DROP TRIGGER IF EXISTS trg_sala_log_update');
    await db.execute('DROP TRIGGER IF EXISTS trg_sala_log_delete');
    await db.execute('DROP TRIGGER IF EXISTS trg_agendamento_log_insert');
    await db.execute('DROP TRIGGER IF EXISTS trg_agendamento_log_update');
    await db.execute('DROP TRIGGER IF EXISTS trg_agendamento_log_delete');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_sala_log_insert
      AFTER INSERT ON sala
      BEGIN
        INSERT INTO log_operacao (
          nome_tabela,
          tipo_operacao,
          data_hora,
          descricao
        )
        VALUES (
          'sala',
          'INSERT',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
          'A sala foi criada "' || NEW.nome || '".'
        );
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_sala_log_update
      AFTER UPDATE ON sala
      BEGIN
        INSERT INTO log_operacao (
          nome_tabela,
          tipo_operacao,
          data_hora,
          descricao
        )
        VALUES (
          'sala',
          'UPDATE',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
          'A sala foi atualizada de "' || OLD.nome || '" para "' || NEW.nome || '".'
        );
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_sala_log_delete
      AFTER DELETE ON sala
      BEGIN
        INSERT INTO log_operacao (
          nome_tabela,
          tipo_operacao,
          data_hora,
          descricao
        )
        VALUES (
          'sala',
          'DELETE',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
          'A sala foi deletada "' || OLD.nome || '".'
        );
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_insert
      AFTER INSERT ON agendamento
      BEGIN
        INSERT INTO log_operacao (
          nome_tabela,
          tipo_operacao,
          data_hora,
          descricao
        )
        VALUES (
          'agendamento',
          'INSERT',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
          'A reuniao foi criada para a sala "' ||
            COALESCE((SELECT nome FROM sala WHERE id = NEW.sala_id), 'ID ' || NEW.sala_id) ||
            '".'
        );
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_update
      AFTER UPDATE ON agendamento
      BEGIN
        INSERT INTO log_operacao (
          nome_tabela,
          tipo_operacao,
          data_hora,
          descricao
        )
        VALUES (
          'agendamento',
          'UPDATE',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
          'A reuniao foi atualizada para a sala "' ||
            COALESCE((SELECT nome FROM sala WHERE id = NEW.sala_id), 'ID ' || NEW.sala_id) ||
            '".'
        );
      END
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_delete
      AFTER DELETE ON agendamento
      BEGIN
        INSERT INTO log_operacao (
          nome_tabela,
          tipo_operacao,
          data_hora,
          descricao
        )
        VALUES (
          'agendamento',
          'DELETE',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
          'A reuniao foi deletada da sala "' ||
            COALESCE((SELECT nome FROM sala WHERE id = OLD.sala_id), 'ID ' || OLD.sala_id) ||
            '".'
        );
      END
    ''');
  }

  Future<void> registerEndedMeetingLogs() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('''
        INSERT INTO log_operacao (
          nome_tabela,
          tipo_operacao,
          data_hora,
          descricao
        )
        SELECT
          'agendamento',
          'ENCERRADA',
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
          'Foi encerrada a reuniao da sala "' || s.nome || '".'
        FROM agendamento a
        JOIN sala s ON s.id = a.sala_id
        WHERE a.fim <= STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
          AND NOT EXISTS (
            SELECT 1
            FROM agendamento_encerramento_log l
            WHERE l.agendamento_id = a.id
          )
      ''');

      await txn.execute('''
        INSERT OR IGNORE INTO agendamento_encerramento_log (
          agendamento_id,
          data_hora
        )
        SELECT
          a.id,
          STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        FROM agendamento a
        WHERE a.fim <= STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
      ''');
    });
  }

  Future<void> _registerEndedMeetingLogsForSala(Transaction txn, int salaId) async {
    await txn.execute('''
      INSERT INTO log_operacao (
        nome_tabela,
        tipo_operacao,
        data_hora,
        descricao
      )
      SELECT
        'agendamento',
        'ENCERRADA',
        STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
        'Foi encerrada a reuniao da sala "' || s.nome || '".'
      FROM agendamento a
      JOIN sala s ON s.id = a.sala_id
      WHERE a.sala_id = ?
        AND a.fim <= STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        AND NOT EXISTS (
          SELECT 1
          FROM agendamento_encerramento_log l
          WHERE l.agendamento_id = a.id
        )
    ''', [salaId]);

    await txn.execute('''
      INSERT OR IGNORE INTO agendamento_encerramento_log (
        agendamento_id,
        data_hora
      )
      SELECT
        a.id,
        STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
      FROM agendamento a
      WHERE a.sala_id = ?
        AND a.fim <= STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
    ''', [salaId]);
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
    return db.transaction((txn) async {
      await _registerEndedMeetingLogsForSala(txn, id);

      final rows = await txn.rawQuery('''
        SELECT COUNT(1) AS total
        FROM agendamento
        WHERE sala_id = ?
          AND inicio > STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
      ''', [id]);
      final totalFuturas = (rows.first['total'] as int?) ?? 0;
      if (totalFuturas > 0) {
        throw Exception(
          'Nao e possivel excluir uma sala com agendamentos futuros.',
        );
      }

      final ongoingRows = await txn.rawQuery('''
        SELECT COUNT(1) AS total
        FROM agendamento
        WHERE sala_id = ?
          AND inicio <= STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
          AND fim > STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
      ''', [id]);
      final totalEmAndamento = (ongoingRows.first['total'] as int?) ?? 0;
      if (totalEmAndamento > 0) {
        throw Exception(
          'Nao e possivel excluir uma sala com reuniao em andamento.',
        );
      }

      await txn.execute('''
        DELETE FROM agendamento_encerramento_log
        WHERE agendamento_id IN (
          SELECT id
          FROM agendamento
          WHERE sala_id = ?
        )
      ''', [id]);

      await txn.execute('''
        DELETE FROM agendamento
        WHERE sala_id = ?
      ''', [id]);

      return txn.delete('sala', where: 'id = ?', whereArgs: [id]);
    });
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
    await registerEndedMeetingLogs();
    final db = await database;
    final rows = await db.query('log_operacao', orderBy: 'id DESC', limit: 200);
    return rows.map(LogOperacao.fromMap).toList();
  }
}
