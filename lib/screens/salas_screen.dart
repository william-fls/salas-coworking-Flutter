import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/sala.dart';

class SalasScreen extends StatefulWidget {
  const SalasScreen({super.key});

  @override
  State<SalasScreen> createState() => _SalasScreenState();
}

class _SalasScreenState extends State<SalasScreen> {
  List<Sala> _salas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _salas = await DatabaseHelper.instance.getSalas();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _showForm({Sala? sala}) async {
    final controller = TextEditingController(text: sala?.nome ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sala == null ? 'Nova Sala' : 'Editar Sala'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome da sala',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final nome = controller.text.trim();
                if (sala == null) {
                  await DatabaseHelper.instance.insertSala(Sala(nome: nome));
                } else {
                  await DatabaseHelper.instance
                      .updateSala(sala.copyWith(nome: nome));
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
    );
  }

  Future<void> _delete(Sala sala) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir sala'),
        content: Text(
          'Deseja excluir a sala "${sala.nome}"? Esta acao nao pode ser desfeita.',
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
      await DatabaseHelper.instance.deleteSala(sala.id!);
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
    if (raw.contains('UNIQUE constraint failed')) {
      return 'Ja existe uma sala com esse nome. Escolha outro nome.';
    }
    if (raw.contains('agendamentos futuros')) {
      return 'Nao e possivel excluir esta sala pois ela possui agendamentos futuros.';
    }
    if (raw.contains('nome da sala')) {
      return 'O nome da sala e obrigatorio.';
    }
    return 'Ocorreu um erro inesperado.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Sala'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _salas.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma sala cadastrada.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _salas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final sala = _salas[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.meeting_room),
                        ),
                        title: Text(sala.nome),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Editar',
                              onPressed: () => _showForm(sala: sala),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              tooltip: 'Excluir',
                              onPressed: () => _delete(sala),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
