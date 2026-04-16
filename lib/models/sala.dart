class Sala {
  final int? id;
  final String nome;

  const Sala({this.id, required this.nome});

  Map<String, dynamic> toMap() => {'id': id, 'nome': nome};

  factory Sala.fromMap(Map<String, dynamic> map) =>
      Sala(id: map['id'] as int?, nome: map['nome'] as String);

  Sala copyWith({int? id, String? nome}) =>
      Sala(id: id ?? this.id, nome: nome ?? this.nome);

  @override
  String toString() => nome;
}
