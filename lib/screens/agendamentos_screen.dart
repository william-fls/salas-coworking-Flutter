import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/agendamento.dart';
import '../models/sala.dart';

class AgendamentosScreen extends StatefulWidget {
  const AgendamentosScreen({super.key});

  @override
  State<AgendamentosScreen> createState() => _AgendamentosScreenState();
}

class _AgendamentosScreenState extends State<AgendamentosScreen> {
  List<Agendamento> _agendamentos = [];
  bool _loading = true;
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _agendamentos = await DatabaseHelper.instance.getAgendamentos();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _showForm({Agendamento? ag}) async {
    if (ag != null && _hasStarted(ag)) {
      _showError(context, 'Nao e possivel alterar uma reuniao apos o inicio.');
      return;
    }

    final salas = await DatabaseHelper.instance.getSalas();
    if (!mounted) return;

    if (salas.isEmpty) {
      _showError(
        context,
        'Cadastre pelo menos uma sala antes de criar um agendamento.',
      );
      return;
    }

    Sala? selectedSala =
        ag != null ? salas.firstWhere((s) => s.id == ag.salaId) : salas.first;
    DateTime inicio = ag?.inicio ?? DateTime.now();
    DateTime fim = ag?.fim ?? DateTime.now().add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(ag == null ? 'Novo Agendamento' : 'Editar Agendamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<Sala>(
                  initialValue: selectedSala,
                  decoration: const InputDecoration(
                    labelText: 'Sala',
                    border: OutlineInputBorder(),
                  ),
                  items: salas
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.nome)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedSala = v),
                ),
                const SizedBox(height: 16),
                _DateTimeField(
                  label: 'Inicio',
                  value: inicio,
                  onChanged: (dt) => setDialogState(() => inicio = dt),
                ),
                const SizedBox(height: 12),
                _DateTimeField(
                  label: 'Fim',
                  value: fim,
                  onChanged: (dt) => setDialogState(() => fim = dt),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (selectedSala == null) {
                  _showError(ctx, 'Selecione uma sala.');
                  return;
                }

                final novo = Agendamento(
                  id: ag?.id,
                  salaId: selectedSala!.id!,
                  inicio: inicio,
                  fim: fim,
                );

                try {
                  if (ag == null) {
                    await DatabaseHelper.instance.insertAgendamento(novo);
                  } else {
                    await DatabaseHelper.instance.updateAgendamento(novo);
                  }

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  _load();
                } on DatabaseException catch (e) {
                  if (ctx.mounted) {
                    _showError(ctx, _friendlyMessage(e.toString()));
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Agendamento ag) async {
    if (_hasStarted(ag)) {
      _showError(context, 'Nao e possivel excluir uma reuniao apos o inicio.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir agendamento'),
        content: Text(
          'Excluir o agendamento da sala "${ag.sala?.nome}" em '
          '${_dateFmt.format(ag.inicio)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DatabaseHelper.instance.deleteAgendamento(ag.id!);
      _load();
    } on DatabaseException catch (e) {
      if (mounted) {
        _showError(context, _friendlyMessage(e.toString()));
      }
    }
  }

  void _showError(BuildContext ctx, String msg) {
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atencao'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _friendlyMessage(String raw) {
    if (raw.contains('nome da sala')) {
      return 'A sala e obrigatoria.';
    }
    if (raw.contains('inicio') && raw.contains('obrigat')) {
      return 'A data/hora de inicio e obrigatoria.';
    }
    if (raw.contains('fim') && raw.contains('obrigat')) {
      return 'A data/hora de fim e obrigatoria.';
    }
    if (raw.contains('fim deve ser maior')) {
      return 'A data/hora de fim deve ser maior que a de inicio.';
    }
    if (raw.contains('agendamento nesse horario')) {
      return 'Ja existe um agendamento nesse horario para a sala selecionada.';
    }
    if (raw.contains('alterar uma reuniao apos o inicio')) {
      return 'Nao e possivel alterar os dados da reuniao apos o inicio.';
    }
    if (raw.contains('reuniao em andamento ou futura')) {
      return 'Nao e possivel excluir uma reuniao em andamento ou futura.';
    }
    if (raw.contains('excluir uma reuniao apos o inicio')) {
      return 'Nao e possivel excluir uma reuniao apos o inicio.';
    }
    return 'Ocorreu um erro inesperado.';
  }

  bool _hasStarted(Agendamento ag) {
    return !DateTime.now().isBefore(ag.inicio);
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            margin: const EdgeInsets.only(right: 8),
            color: color,
          ),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final visible = _agendamentos.where((a) => !a.fim.isBefore(now)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Agendamentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Agendamento'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : visible.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma reuniao futura ou em andamento.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (visible.isNotEmpty) ...[
                      _sectionHeader('Proximos / Em andamento', Colors.green),
                      ...visible.map(
                        (ag) {
                          final locked = _hasStarted(ag);
                          return _AgendamentoCard(
                            ag: ag,
                            dateFmt: _dateFmt,
                            onEdit: locked ? null : () => _showForm(ag: ag),
                            onDelete: locked ? null : () => _delete(ag),
                            muted: locked,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
    );
  }
}

class _AgendamentoCard extends StatelessWidget {
  const _AgendamentoCard({
    required this.ag,
    required this.dateFmt,
    required this.onEdit,
    required this.onDelete,
    this.muted = false,
  });

  final Agendamento ag;
  final DateFormat dateFmt;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: muted ? cs.surfaceContainerHighest.withValues(alpha: 0.5) : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: muted ? Colors.grey.shade300 : cs.primaryContainer,
          child: Icon(
            Icons.event,
            color: muted ? Colors.grey : cs.onPrimaryContainer,
          ),
        ),
        title: Text(
          ag.sala?.nome ?? 'Sala #${ag.salaId}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: muted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          'Inicio: ${dateFmt.format(ag.inicio)}\n'
          'Fim:    ${dateFmt.format(ag.fim)}',
          style: TextStyle(color: muted ? Colors.grey : null),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: onDelete == null ? cs.outline : cs.error,
              ),
              tooltip: 'Excluir',
              onPressed: onDelete,
            ),
            if (onEdit == null && onDelete == null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.lock_outline, size: 18, color: cs.outline),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date == null || !context.mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time == null) return;

        onChanged(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(fmt.format(value)),
      ),
    );
  }
}
