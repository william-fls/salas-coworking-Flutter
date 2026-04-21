# Coworking Rooms

Aplicacao Flutter para gerenciamento de salas, agendamentos e historico de operacoes, com persistencia em SQLite.

## Status atual do projeto

- Navegacao por 3 abas: `Agendamentos`, `Salas` e `Logs`.
- Plataformas ativas no repositorio: Android, Web e Windows.
- Android, Web e Windows foram desenvolvidos e testados.
- Linux, macOS e iOS foram removidos do projeto por falta de um ambiente disponivel para validacao e testes dessas plataformas.
- Banco local com schema e regras de negocio aplicadas por triggers SQLite.
- Testes automatizados atuais: 1 teste unitario para `Sala.copyWith`.

## Funcionalidades implementadas

### Agendamentos

- Criar e editar agendamentos.
- A listagem exibe apenas reunioes futuras ou em andamento.
- Reunioes finalizadas nao aparecem na tela de agendamentos.
- Nao e permitido editar reunioes apos o horario de inicio.
- A interface nao oferece exclusao direta de agendamentos.

### Salas

- Criar, editar e excluir salas.
- Nome da sala obrigatorio e unico (comparacao case-insensitive).
- Exclusao bloqueada quando a sala possui reuniao futura ou em andamento.
- Ao excluir uma sala permitida, os agendamentos finalizados vinculados a ela sao removidos.

### Logs

- Registro automatico para `INSERT`, `UPDATE` e `DELETE` em `sala` e `agendamento`.
- Registro adicional de reunioes encerradas com tipo `ENCERRADA`.
- Mensagens de log com descricao textual (incluindo nome da sala quando disponivel).
- A tela retorna todos os registros existentes no banco.

## Regras de negocio (banco de dados)

- `sala.nome` nao pode ser vazio e deve ser unico (`COLLATE NOCASE`).
- `agendamento` exige `sala_id`, `inicio` e `fim`.
- `fim` deve ser maior que `inicio`.
- Nao sao permitidos agendamentos sobrepostos para a mesma sala.
- Nao e permitido atualizar reuniao apos o inicio.
- Nao e permitido excluir reuniao em andamento ou futura.
- Nao e permitido excluir sala com reuniao futura ou em andamento.

## Estrutura principal

```text
lib/
  database/
    database_factory_setup_io.dart
    database_factory_setup_stub.dart
    database_factory_setup_web.dart
    database_helper.dart
  models/
    agendamento.dart
    log_operacao.dart
    sala.dart
  screens/
    agendamentos_screen.dart
    logs_screen.dart
    salas_screen.dart
  utils/
    dialog_utils.dart
    message_mapper.dart
  main.dart

database.sql
test/widget_test.dart
```

## Tecnologias

- Flutter (Material 3)
- `sqflite`
- `sqflite_common_ffi` (Windows)
- `sqflite_common_ffi_web` (Web)
- `intl`
- `path`

## Como executar

### Pre-requisitos

- Flutter SDK 3.x ou superior
- Ambiente Android, Web ou Windows habilitado no Flutter

### Instalar dependencias

```bash
flutter pub get
```

### Rodar o app

```bash
flutter run
```

Exemplo para Windows:

```bash
flutter run -d windows
```

Exemplo para Web:

```bash
flutter run -d chrome
```

## Banco de dados

- O schema e criado programaticamente em `DatabaseHelper` (versao atual: 10).
- O arquivo [database.sql](./database.sql) permanece como referencia do schema e triggers.

## Testes

```bash
flutter test
```
