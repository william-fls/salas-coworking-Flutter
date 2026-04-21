# Coworking Rooms

Aplicacao Flutter com SQLite para gerenciamento de salas de coworking, agendamentos e historico de operacoes.

## Funcionalidades

- Cadastro, edicao e exclusao de salas.
- Criacao e edicao de agendamentos.
- A interface atual nao expoe exclusao direta de agendamentos.
- Bloqueio de conflitos de horario para a mesma sala.
- Historico automatico de operacoes em log.
- Suporte ativo para Android, Web e Windows.

## Plataformas suportadas

- Android
- Web
- Windows

## Plataformas removidas deste repositorio

- iOS
- macOS
- Linux

As pastas dessas plataformas foram removidas para manter o projeto alinhado ao ambiente de testes disponivel.

## Regras de negocio

- O nome da sala e obrigatorio e unico, sem diferenciar maiusculas de minusculas.
- Todo agendamento precisa informar sala, inicio e fim.
- A data e hora final deve ser maior que a inicial.
- Nao e permitido criar agendamentos sobrepostos para a mesma sala.
- Nao e permitido alterar agendamentos apos o inicio da reuniao.
- Uma sala so pode ser excluida quando todas as suas reunioes estiverem finalizadas.
- Ao excluir a sala, os agendamentos finalizados vinculados a ela sao removidos automaticamente.
- Insercoes, alteracoes e exclusoes em `sala` e `agendamento` geram log automatico em `log_operacao`.
- Encerramentos de reuniao tambem sao registrados automaticamente no log com tipo `ENCERRADA`.
- As mensagens de log incluem o nome da sala (ex.: sala criada/deletada e reuniao encerrada).

## Estrutura do projeto

```text
lib/
  database/
    database_factory_setup_io.dart
    database_factory_setup_stub.dart
    database_factory_setup_web.dart
    database_helper.dart
  models/
  screens/
  main.dart

database.sql
```

## Tecnologias

- Flutter
- SQLite com `sqflite`
- `sqflite_common_ffi` para Windows desktop
- `sqflite_common_ffi_web` para Web
- `intl` para formatacao de data e hora
- `path` para resolucao do arquivo do banco

## Como executar

### Pre-requisitos

- Flutter SDK 3.x ou superior
- Um dispositivo ou emulador Android, ou ambiente Windows/Web habilitado

### Passos

```bash
git clone https://github.com/<seu-usuario>/salas-coworking-Flutter.git
cd salas-coworking-Flutter
flutter pub get
flutter run
```

Para rodar em um alvo especifico, por exemplo no Windows:

```bash
flutter run -d windows
```

## Banco de dados

O arquivo [database.sql](./database.sql) contem o script de criacao do schema e das triggers usadas na aplicacao.

Na execucao normal do app, a criacao do banco e feita pelo `DatabaseHelper`, enquanto o script SQL serve como referencia e apoio para testes manuais.
