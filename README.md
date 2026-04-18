# Coworking Rooms

Aplicação Flutter com SQLite para gerenciamento de salas de coworking, agendamentos e histórico de operações.

## Funcionalidades

- Cadastro, edição e exclusão de salas.
- Criação, edição e exclusão de agendamentos.
- Bloqueio de conflitos de horário para a mesma sala.
- Histórico automático de operações em log.
- Suporte a mobile e desktop, com configuração de banco para Windows, Linux e macOS.

## Regras de negócio

- O nome da sala é obrigatório e único, sem diferenciar maiúsculas de minúsculas.
- Todo agendamento precisa informar sala, início e fim.
- A data e hora final deve ser maior que a inicial.
- Não é permitido criar agendamentos sobrepostos para a mesma sala.
- Não é permitido alterar ou excluir agendamentos após o início da reunião.
- Exclusão direta de agendamento só é permitida para reuniões já encerradas.
- Uma sala só pode ser excluída quando todas as suas reuniões estiverem finalizadas.
- Ao excluir a sala, os agendamentos finalizados vinculados a ela são removidos automaticamente.
- Inserções, alterações e exclusões em `sala` e `agendamento` geram log automático em `log_operacao`.
- Encerramentos de reunião também são registrados automaticamente no log com tipo `ENCERRADA`.
- As mensagens de log incluem o nome da sala (ex.: sala criada/deletada e reunião encerrada).

## Estrutura do projeto

```text
lib/
  database/
    database_factory_setup_io.dart
    database_factory_setup_stub.dart
    database_helper.dart
  models/
  screens/
  main.dart

database.sql
```

## Tecnologias

- Flutter
- SQLite com `sqflite`
- `sqflite_common_ffi` para desktop
- `intl` para formatação de data e hora
- `path` para resolução do arquivo do banco

## Como executar

### Pré-requisitos

- Flutter SDK 3.x ou superior
- Um dispositivo, emulador ou ambiente desktop habilitado

### Passos

```bash
git clone https://github.com/<seu-usuario>/salas-coworking-Flutter.git
cd salas-coworking-Flutter
flutter pub get
flutter run
```

Para rodar em um alvo específico, por exemplo no Windows:

```bash
flutter run -d windows
```

## Banco de dados

O arquivo [database.sql](./database.sql) contém o script de criação do schema e das triggers usadas na aplicação.

Na execução normal do app, a criação do banco é feita pelo `DatabaseHelper`, enquanto o script SQL serve como referência e apoio para testes manuais.
