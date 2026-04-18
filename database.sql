-- ============================================================
-- Sistema de Agendamentos de Salas Coworking
-- Script de criação do banco de dados SQLite
-- ============================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- ------------------------------------------------------------
-- Tabela: sala
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sala (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT    NOT NULL
);

-- Unicidade do nome (case-insensitive)
CREATE UNIQUE INDEX IF NOT EXISTS uq_sala_nome ON sala (nome COLLATE NOCASE);

-- ------------------------------------------------------------
-- Tabela: agendamento
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agendamento (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    sala_id      INTEGER NOT NULL,
    inicio       TEXT    NOT NULL,   -- ISO-8601: "YYYY-MM-DD HH:MM:SS"
    fim          TEXT    NOT NULL,   -- ISO-8601: "YYYY-MM-DD HH:MM:SS"
    CONSTRAINT fk_agendamento_sala
        FOREIGN KEY (sala_id) REFERENCES sala (id)
);

-- ------------------------------------------------------------
-- Tabela: log_operacao
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS log_operacao (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_tabela     TEXT    NOT NULL,
    tipo_operacao   TEXT    NOT NULL,   -- INSERT | UPDATE | DELETE | ENCERRADA
    data_hora       TEXT    NOT NULL,   -- ISO-8601
    descricao       TEXT
);

-- Controle para evitar logs duplicados de encerramento automatico
CREATE TABLE IF NOT EXISTS agendamento_encerramento_log (
    agendamento_id  INTEGER PRIMARY KEY,
    data_hora       TEXT    NOT NULL,
    CONSTRAINT fk_encerramento_agendamento
        FOREIGN KEY (agendamento_id) REFERENCES agendamento (id)
);

-- ============================================================
-- Triggers: sala
-- ============================================================

CREATE TRIGGER IF NOT EXISTS trg_sala_before_insert
BEFORE INSERT ON sala
BEGIN
    SELECT CASE
        WHEN NEW.nome IS NULL OR TRIM(NEW.nome) = ''
        THEN RAISE(ABORT, 'O nome da sala é obrigatório.')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_sala_log_insert
AFTER INSERT ON sala
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora, descricao)
    VALUES (
        'sala',
        'INSERT',
        STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
        'A sala foi criada "' || NEW.nome || '".'
    );
END;

CREATE TRIGGER IF NOT EXISTS trg_sala_before_update
BEFORE UPDATE ON sala
BEGIN
    SELECT CASE
        WHEN NEW.nome IS NULL OR TRIM(NEW.nome) = ''
        THEN RAISE(ABORT, 'O nome da sala é obrigatório.')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_sala_log_update
AFTER UPDATE ON sala
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora, descricao)
    VALUES (
        'sala',
        'UPDATE',
        STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
        'A sala foi atualizada de "' || OLD.nome || '" para "' || NEW.nome || '".'
    );
END;

CREATE TRIGGER IF NOT EXISTS trg_sala_before_delete
BEFORE DELETE ON sala
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM agendamento
            WHERE sala_id = OLD.id
              AND fim > STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        )
        THEN RAISE(ABORT, 'Não é possível excluir uma sala com agendamentos futuros.')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_sala_log_delete
AFTER DELETE ON sala
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora, descricao)
    VALUES (
        'sala',
        'DELETE',
        STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
        'A sala foi deletada "' || OLD.nome || '".'
    );
END;

-- ============================================================
-- Triggers: agendamento
-- ============================================================

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
        THEN RAISE(ABORT, 'Já existe um agendamento nesse horário para a sala selecionada.')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_insert
AFTER INSERT ON agendamento
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora, descricao)
    VALUES (
        'agendamento',
        'INSERT',
        STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
        'A reuniao foi criada para a sala "' ||
            COALESCE((SELECT nome FROM sala WHERE id = NEW.sala_id), 'ID ' || NEW.sala_id) ||
            '".'
    );
END;

CREATE TRIGGER IF NOT EXISTS trg_agendamento_before_update
BEFORE UPDATE ON agendamento
BEGIN
    SELECT CASE
        WHEN OLD.inicio <= STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        THEN RAISE(ABORT, 'Nao e possivel alterar uma reuniao apos o inicio.')
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
        THEN RAISE(ABORT, 'Já existe um agendamento nesse horário para a sala selecionada.')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_update
AFTER UPDATE ON agendamento
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora, descricao)
    VALUES (
        'agendamento',
        'UPDATE',
        STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
        'A reuniao foi atualizada para a sala "' ||
            COALESCE((SELECT nome FROM sala WHERE id = NEW.sala_id), 'ID ' || NEW.sala_id) ||
            '".'
    );
END;

CREATE TRIGGER IF NOT EXISTS trg_agendamento_before_delete
BEFORE DELETE ON agendamento
BEGIN
    SELECT CASE
        WHEN OLD.fim > STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        THEN RAISE(ABORT, 'Nao e possivel excluir uma reuniao em andamento ou futura.')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_delete
AFTER DELETE ON agendamento
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora, descricao)
    VALUES (
        'agendamento',
        'DELETE',
        STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'),
        'A reuniao foi deletada da sala "' ||
            COALESCE((SELECT nome FROM sala WHERE id = OLD.sala_id), 'ID ' || OLD.sala_id) ||
            '".'
    );
END;

-- Regra final de exclusao da sala:
-- so permite excluir quando todas as reunioes da sala estiverem finalizadas.
DROP TRIGGER IF EXISTS trg_sala_before_delete;
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
        THEN RAISE(ABORT, 'Nao e possivel excluir uma sala com agendamentos futuros.')
        WHEN EXISTS (
            SELECT 1
            FROM agendamento
            WHERE sala_id = OLD.id
              AND inicio <= STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
              AND fim > STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        )
        THEN RAISE(ABORT, 'Nao e possivel excluir uma sala com reuniao em andamento.')
    END;
END;
