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
    tipo_operacao   TEXT    NOT NULL,   -- INSERT | UPDATE | DELETE
    data_hora       TEXT    NOT NULL    -- ISO-8601
);

-- ============================================================
-- TRIGGERS — sala
-- ============================================================

-- Validação: nome obrigatório (INSERT)
CREATE TRIGGER IF NOT EXISTS trg_sala_before_insert
BEFORE INSERT ON sala
BEGIN
    SELECT CASE
        WHEN NEW.nome IS NULL OR TRIM(NEW.nome) = ''
        THEN RAISE(ABORT, 'O nome da sala é obrigatório.')
    END;
END;

-- Log INSERT sala
CREATE TRIGGER IF NOT EXISTS trg_sala_log_insert
AFTER INSERT ON sala
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
    VALUES ('sala', 'INSERT', STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'));
END;

-- Validação: nome obrigatório (UPDATE)
CREATE TRIGGER IF NOT EXISTS trg_sala_before_update
BEFORE UPDATE ON sala
BEGIN
    SELECT CASE
        WHEN NEW.nome IS NULL OR TRIM(NEW.nome) = ''
        THEN RAISE(ABORT, 'O nome da sala é obrigatório.')
    END;
END;

-- Log UPDATE sala
CREATE TRIGGER IF NOT EXISTS trg_sala_log_update
AFTER UPDATE ON sala
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
    VALUES ('sala', 'UPDATE', STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'));
END;

-- Validação: não permitir exclusão se houver agendamento futuro
CREATE TRIGGER IF NOT EXISTS trg_sala_before_delete
BEFORE DELETE ON sala
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM agendamento
            WHERE sala_id = OLD.id
              AND inicio > STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime')
        )
        THEN RAISE(ABORT, 'Não é possível excluir uma sala com agendamentos futuros.')
    END;
END;

-- Log DELETE sala
CREATE TRIGGER IF NOT EXISTS trg_sala_log_delete
AFTER DELETE ON sala
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
    VALUES ('sala', 'DELETE', STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'));
END;

-- ============================================================
-- TRIGGERS — agendamento
-- ============================================================

-- Validação INSERT agendamento
CREATE TRIGGER IF NOT EXISTS trg_agendamento_before_insert
BEFORE INSERT ON agendamento
BEGIN
    -- Campos obrigatórios
    SELECT CASE
        WHEN NEW.sala_id IS NULL
        THEN RAISE(ABORT, 'A sala é obrigatória.')
        WHEN NEW.inicio IS NULL OR TRIM(NEW.inicio) = ''
        THEN RAISE(ABORT, 'A data/hora de início é obrigatória.')
        WHEN NEW.fim IS NULL OR TRIM(NEW.fim) = ''
        THEN RAISE(ABORT, 'A data/hora de fim é obrigatória.')
        -- fim deve ser maior que inicio
        WHEN NEW.fim <= NEW.inicio
        THEN RAISE(ABORT, 'A data/hora de fim deve ser maior que a de início.')
        -- sobreposição de horários
        WHEN EXISTS (
            SELECT 1 FROM agendamento
            WHERE sala_id = NEW.sala_id
              AND NEW.inicio < fim
              AND NEW.fim   > inicio
        )
        THEN RAISE(ABORT, 'Já existe um agendamento nesse horário para a sala selecionada.')
    END;
END;

-- Log INSERT agendamento
CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_insert
AFTER INSERT ON agendamento
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
    VALUES ('agendamento', 'INSERT', STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'));
END;

-- Validação UPDATE agendamento
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
            SELECT 1 FROM agendamento
            WHERE sala_id = NEW.sala_id
              AND id      != NEW.id
              AND NEW.inicio < fim
              AND NEW.fim   > inicio
        )
        THEN RAISE(ABORT, 'Já existe um agendamento nesse horário para a sala selecionada.')
    END;
END;

-- Log UPDATE agendamento
CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_update
AFTER UPDATE ON agendamento
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
    VALUES ('agendamento', 'UPDATE', STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'));
END;

-- Log DELETE agendamento
CREATE TRIGGER IF NOT EXISTS trg_agendamento_log_delete
AFTER DELETE ON agendamento
BEGIN
    INSERT INTO log_operacao (nome_tabela, tipo_operacao, data_hora)
    VALUES ('agendamento', 'DELETE', STRFTIME('%Y-%m-%d %H:%M:%S', 'now', 'localtime'));
END;
