import 'sala.dart';

class Agendamento {
  final int? id;
  final int salaId;
  final DateTime inicio;
  final DateTime fim;

  // Populated via JOIN — not persisted
  final Sala? sala;

  const Agendamento({
    this.id,
    required this.salaId,
    required this.inicio,
    required this.fim,
    this.sala,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sala_id': salaId,
        'inicio': _fmt(inicio),
        'fim': _fmt(fim),
      };

  factory Agendamento.fromMap(Map<String, dynamic> map, {Sala? sala}) =>
      Agendamento(
        id: map['id'] as int?,
        salaId: map['sala_id'] as int,
        inicio: DateTime.parse(map['inicio'] as String),
        fim: DateTime.parse(map['fim'] as String),
        sala: sala,
      );

  static String _fmt(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}
