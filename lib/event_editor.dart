import 'dart:convert';
import 'package:flutter/material.dart';
import 'models.dart';

class EventEditorDialog extends StatefulWidget {
  const EventEditorDialog({super.key, required this.event});
  final EventData event;
  @override
  State<EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<EventEditorDialog> {
  int selectedPageIndex = 0;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.event.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.event.pages;
    if (selectedPageIndex >= pages.length) {
      selectedPageIndex = pages.isEmpty ? 0 : pages.length - 1;
    }
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.flag),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Nom de l’événement'),
              onChanged: (v) => widget.event.name = v,
            ),
          ),
          Text('(${widget.event.x}, ${widget.event.y})', style: const TextStyle(color: Colors.black54)),
        ],
      ),
      content: SizedBox(
        width: 820,
        height: 520,
        child: Row(
          children: [
            _buildPagesSidebar(pages),
            const VerticalDivider(width: 1),
            Expanded(child: _buildPageEditor(pages.isEmpty ? null : pages[selectedPageIndex])),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildPagesSidebar(List<EventPage> pages) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Pages', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Ajouter une page',
                onPressed: () {
                  setState(() {
                    pages.add(EventPage(commands: [EventCommand('ShowText', {'text': 'Bonjour!'})]));
                    selectedPageIndex = pages.length - 1;
                  });
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pages.length,
              itemBuilder: (_, i) {
                final isSel = i == selectedPageIndex;
                return ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text('Page ${i + 1} — ${pages[i].trigger}'),
                  selected: isSel,
                  onTap: () => setState(() => selectedPageIndex = i),
                  trailing: IconButton(
                    tooltip: 'Supprimer',
                    onPressed: () {
                      setState(() {
                        pages.removeAt(i);
                        if (selectedPageIndex >= pages.length) {
                          selectedPageIndex = (pages.length - 1).clamp(0, pages.length);
                        }
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageEditor(EventPage? page) {
    if (page == null) {
      return const Center(child: Text('Aucune page'));
    }
    final condCtrl = TextEditingController(text: const JsonEncoder.withIndent('  ').convert(page.conditions));
    final List<String> triggers = const ['ActionButton', 'PlayerTouch', 'Autorun', 'Parallel'];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Conditions & Déclencheur', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: condCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Conditions (JSON)', border: OutlineInputBorder()),
                  onChanged: (v) {
                    try {
                      final decoded = jsonDecode(v);
                      if (decoded is Map<String, dynamic>) {
                        page.conditions.clear();
                        page.conditions.addAll(decoded);
                      }
                    } catch (_) {}
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: page.trigger,
                items: [for (final t in triggers) DropdownMenuItem(value: t, child: Text(t))],
                onChanged: (v) => setState(() => page.trigger = v ?? page.trigger),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Commandes', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: page.commands.length,
              itemBuilder: (_, i) {
                final cmd = page.commands[i];
                final paramsCtrl = TextEditingController(text: const JsonEncoder.withIndent('  ').convert(cmd.params));
                final codeCtrl = TextEditingController(text: cmd.code);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: codeCtrl,
                                decoration: const InputDecoration(labelText: 'Code'),
                                onChanged: (v) => cmd.code = v,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Monter',
                              onPressed: i == 0
                                  ? null
                                  : () => setState(() {
                                        final tmp = page.commands.removeAt(i);
                                        page.commands.insert(i - 1, tmp);
                                      }),
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            IconButton(
                              tooltip: 'Descendre',
                              onPressed: i == page.commands.length - 1
                                  ? null
                                  : () => setState(() {
                                        final tmp = page.commands.removeAt(i);
                                        page.commands.insert(i + 1, tmp);
                                      }),
                              icon: const Icon(Icons.arrow_downward),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              onPressed: () => setState(() => page.commands.removeAt(i)),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: paramsCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Paramètres (JSON)', border: OutlineInputBorder()),
                          onChanged: (v) {
                            try {
                              final decoded = jsonDecode(v);
                              if (decoded is Map<String, dynamic>) {
                                cmd.params.clear();
                                cmd.params.addAll(decoded);
                              }
                            } catch (_) {}
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => setState(() => page.commands.add(EventCommand('ShowText', {'text': '...'}))),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter commande'),
            ),
          ),
        ],
      ),
    );
  }
}