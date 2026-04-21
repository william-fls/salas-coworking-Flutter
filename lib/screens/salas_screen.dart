import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/sala.dart';
import '../utils/dialog_utils.dart';
import '../utils/message_mapper.dart';

class SalasScreen extends StatefulWidget {
  const SalasScreen({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<SalasScreen> createState() => _SalasScreenState();
}

class _SalasScreenState extends State<SalasScreen> {
  static const _friendlyMessageRules = <MapEntry<String, String>>[
    MapEntry(
      'UNIQUE constraint failed',
      'Ja existe uma sala com esse nome. Escolha outro nome.',
    ),
    MapEntry(
      'agendamentos futuros',
      'Nao e possivel excluir esta sala porque ela possui agendamentos futuros.',
    ),
    MapEntry(
      'reuniao em andamento',
      'Nao e possivel excluir esta sala porque ela possui reuniao em andamento.',
    ),
    MapEntry(
      'reunioes em andamento ou futuras',
      'Nao e possivel excluir esta sala porque ela ainda possui reunioes em andamento ou futuras.',
    ),
    MapEntry(
      'FOREIGN KEY constraint failed',
      'Nao foi possivel excluir a sala porque existem reunioes vinculadas que ainda nao terminaram.',
    ),
    MapEntry('nome da sala', 'O nome da sala e obrigatorio.'),
  ];

  List<Sala> _salas = [];
  Set<int> _salaIdsComExclusaoBloqueada = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SalasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      DatabaseHelper.instance.getSalas(),
      DatabaseHelper.instance.getSalaIdsComExclusaoBloqueada(),
    ]);
    _salas = results[0] as List<Sala>;
    _salaIdsComExclusaoBloqueada = results[1] as Set<int>;
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
                  showAttentionDialog(ctx, _friendlyMessage(e.toString()));
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
    if (_exclusaoBloqueada(sala)) {
      showAttentionDialog(
        context,
        'Nao e possivel excluir esta sala porque ela possui agendamentos futuros ou reuniao em andamento.',
      );
      return;
    }

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
    } catch (e) {
      if (mounted) {
        showAttentionDialog(context, _friendlyMessage(e.toString()));
      }
    }
  }

  bool _exclusaoBloqueada(Sala sala) {
    final salaId = sala.id;
    return salaId != null && _salaIdsComExclusaoBloqueada.contains(salaId);
  }

  String _friendlyMessage(String raw) {
    return mapMessageByRules(raw, containsRules: _friendlyMessageRules);
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
                    final exclusaoBloqueada = _exclusaoBloqueada(sala);
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
                            if (!exclusaoBloqueada)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                tooltip: 'Excluir',
                                onPressed: () => _delete(sala),
                              )
                            else
                              Tooltip(
                                message:
                                    'Sala com agendamentos futuros ou reuniao em andamento nao pode ser excluida.',
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
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
