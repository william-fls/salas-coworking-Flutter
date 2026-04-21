import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/log_operacao.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<LogOperacao> _logs = [];
  bool _loading = true;
  final _fmt = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _logs = await DatabaseHelper.instance.getLogs();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Color _colorFor(String tipo) => switch (tipo) {
        'INSERT' => Colors.green,
        'UPDATE' => Colors.orange,
        'DELETE' => Colors.red,
        'ENCERRADA' => Colors.blueGrey,
        _ => Colors.grey,
      };

  String _labelFor(String tipo) => switch (tipo) {
        'INSERT' => 'Criado',
        'UPDATE' => 'Atualizacao',
        'DELETE' => 'Excluido',
        'ENCERRADA' => 'ENCERRADA',
        _ => tipo,
      };

  String _titleFor(LogOperacao log) {
    final descricao = log.descricao?.trim();
    if (descricao != null && descricao.isNotEmpty) {
      return descricao;
    }
    if (log.tipoOperacao == 'ENCERRADA' && log.nomeTabela == 'agendamento') {
      return 'Foi encerrada a reuniao.';
    }
    return log.nomeTabela;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log de Operações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('Nenhum log registrado.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final log = _logs[i];
                    final color = _colorFor(log.tipoOperacao);
                    return ListTile(
                      dense: true,
                      leading: Chip(
                        label: Text(
                          _labelFor(log.tipoOperacao),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: color,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      title: Text(
                        _titleFor(log),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(_fmt.format(log.dataHora)),
                    );
                  },
                ),
    );
  }
}
