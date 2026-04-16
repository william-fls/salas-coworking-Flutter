class LogOperacao {
  final int? id;
  final String nomeTabela;
  final String tipoOperacao;
  final DateTime dataHora;

  const LogOperacao({
    this.id,
    required this.nomeTabela,
    required this.tipoOperacao,
    required this.dataHora,
  });

  factory LogOperacao.fromMap(Map<String, dynamic> map) => LogOperacao(
        id: map['id'] as int?,
        nomeTabela: map['nome_tabela'] as String,
        tipoOperacao: map['tipo_operacao'] as String,
        dataHora: DateTime.parse(map['data_hora'] as String),
      );
}
