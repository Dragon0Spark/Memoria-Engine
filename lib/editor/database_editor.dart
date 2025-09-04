import 'dart:io';

import 'package:flutter/material.dart';

import '../database.dart';

/// Simple database editor with tabs for heroes, classes and database entries
/// similar to classic RPG editors.
class DatabaseEditor extends StatefulWidget {
  const DatabaseEditor({super.key});

  @override
  State<DatabaseEditor> createState() => _DatabaseEditorState();
}

class _DatabaseEditorState extends State<DatabaseEditor> with TickerProviderStateMixin {
  late GameDatabase _db;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = Directory('data');
    _db = await GameDatabase.load(dir);
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final dir = Directory('data');
    await _db.save(dir);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base de données sauvegardée')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return DefaultTabController(
      length: 10,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Base de données'),
          actions: [
            IconButton(onPressed: _save, icon: const Icon(Icons.save)),
          ],
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Héros'),
            Tab(text: 'Classes'),
            Tab(text: 'Compétences'),
            Tab(text: 'Objets'),
            Tab(text: 'Armes'),
            Tab(text: 'Armures'),
            Tab(text: 'Ennemis'),
            Tab(text: 'Groupes'),
            Tab(text: 'États'),
            Tab(text: 'Animations'),
          ]),
        ),
        body: TabBarView(children: [
          _HeroesTab(db: _db),
          _ClassesTab(db: _db),
          _SkillsTab(db: _db),
          _ItemsTab(db: _db),
          _WeaponsTab(db: _db),
          _ArmorsTab(db: _db),
          _EnemiesTab(db: _db),
          _TroopsTab(db: _db),
          _StatesTab(db: _db),
          _AnimationsTab(db: _db),
        ]),
      ),
    );
  }
}

class _HeroesTab extends StatefulWidget {
  const _HeroesTab({required this.db});
  final GameDatabase db;
  @override
  State<_HeroesTab> createState() => _HeroesTabState();
}

class _HeroesTabState extends State<_HeroesTab> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ListView(
          children: widget.db.heroes.map((h) {
            return ListTile(
              title: Text(h.name),
              selected: h.id == _selectedId,
              onTap: () => setState(() => _selectedId = h.id),
            );
          }).toList(),
        ),
      ),
      Expanded(
        flex: 2,
        child: _selectedId == null
            ? const Center(child: Text('Sélectionnez un héros'))
            : _HeroEditor(hero: widget.db.heroes.firstWhere((e) => e.id == _selectedId)),
      ),
    ]);
  }
}

class _HeroEditor extends StatefulWidget {
  const _HeroEditor({required this.hero});
  final HeroData hero;
  @override
  State<_HeroEditor> createState() => _HeroEditorState();
}

class _HeroEditorState extends State<_HeroEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _classCtrl;
  late final TextEditingController _levelCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.hero.name);
    _classCtrl = TextEditingController(text: widget.hero.classId.toString());
    _levelCtrl = TextEditingController(text: widget.hero.level.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _levelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => widget.hero.name = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _classCtrl,
            decoration: const InputDecoration(labelText: 'ID Classe'),
            keyboardType: TextInputType.number,
            onChanged: (v) => widget.hero.classId = int.tryParse(v) ?? widget.hero.classId,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _levelCtrl,
            decoration: const InputDecoration(labelText: 'Niveau'),
            keyboardType: TextInputType.number,
            onChanged: (v) => widget.hero.level = int.tryParse(v) ?? widget.hero.level,
          ),
        ],
      ),
    );
  }
}

class _ClassesTab extends StatefulWidget {
  const _ClassesTab({required this.db});
  final GameDatabase db;
  @override
  State<_ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<_ClassesTab> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ListView(
          children: widget.db.classes.map((c) {
            return ListTile(
              title: Text(c.name),
              selected: c.id == _selectedId,
              onTap: () => setState(() => _selectedId = c.id),
            );
          }).toList(),
        ),
      ),
      Expanded(
        flex: 2,
        child: _selectedId == null
            ? const Center(child: Text('Sélectionnez une classe'))
            : _ClassEditor(cls: widget.db.classes.firstWhere((e) => e.id == _selectedId)),
      ),
    ]);
  }
}

class _ClassEditor extends StatefulWidget {
  const _ClassEditor({required this.cls});
  final ClassData cls;
  @override
  State<_ClassEditor> createState() => _ClassEditorState();
}

class _ClassEditorState extends State<_ClassEditor> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.cls.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => widget.cls.name = v,
          ),
        ],
      ),
    );
  }
}

class _ItemsTab extends StatefulWidget {
  const _ItemsTab({required this.db});
  final GameDatabase db;
  @override
  State<_ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<_ItemsTab> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ListView(
          children: widget.db.items.map((i) {
            return ListTile(
              title: Text(i.name),
              selected: i.id == _selectedId,
              onTap: () => setState(() => _selectedId = i.id),
            );
          }).toList(),
        ),
      ),
      Expanded(
        flex: 2,
        child: _selectedId == null
            ? const Center(child: Text('Sélectionnez un objet'))
            : _ItemEditor(item: widget.db.items.firstWhere((e) => e.id == _selectedId)),
      ),
    ]);
  }
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({required this.item});
  final ItemData item;
  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _descCtrl = TextEditingController(text: widget.item.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => widget.item.name = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (v) => widget.item.description = v,
          ),
        ],
      ),
    );
  }
}

// ---- Skills ----

class _SkillsTab extends StatefulWidget {
  const _SkillsTab({required this.db});
  final GameDatabase db;
  @override
  State<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<_SkillsTab> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ListView(
          children: widget.db.skills.map((s) {
            return ListTile(
              title: Text(s.name),
              selected: s.id == _selectedId,
              onTap: () => setState(() => _selectedId = s.id),
            );
          }).toList(),
        ),
      ),
      Expanded(
        flex: 2,
        child: _selectedId == null
            ? const Center(child: Text('Sélectionnez une compétence'))
            : _SkillEditor(skill: widget.db.skills.firstWhere((e) => e.id == _selectedId)),
      ),
    ]);
  }
}

class _SkillEditor extends StatefulWidget {
  const _SkillEditor({required this.skill});
  final SkillData skill;
  @override
  State<_SkillEditor> createState() => _SkillEditorState();
}

class _SkillEditorState extends State<_SkillEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.skill.name);
    _descCtrl = TextEditingController(text: widget.skill.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => widget.skill.name = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (v) => widget.skill.description = v,
          ),
        ],
      ),
    );
  }
}

// ---- Weapons ----

class _WeaponsTab extends StatefulWidget {
  const _WeaponsTab({required this.db});
  final GameDatabase db;
  @override
  State<_WeaponsTab> createState() => _WeaponsTabState();
}

class _WeaponsTabState extends State<_WeaponsTab> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ListView(
          children: widget.db.weapons.map((w) {
            return ListTile(
              title: Text(w.name),
              selected: w.id == _selectedId,
              onTap: () => setState(() => _selectedId = w.id),
            );
          }).toList(),
        ),
      ),
      Expanded(
        flex: 2,
        child: _selectedId == null
            ? const Center(child: Text('Sélectionnez une arme'))
            : _WeaponEditor(weapon: widget.db.weapons.firstWhere((e) => e.id == _selectedId)),
      ),
    ]);
  }
}

class _WeaponEditor extends StatefulWidget {
  const _WeaponEditor({required this.weapon});
  final WeaponData weapon;
  @override
  State<_WeaponEditor> createState() => _WeaponEditorState();
}

class _WeaponEditorState extends State<_WeaponEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.weapon.name);
    _descCtrl = TextEditingController(text: widget.weapon.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => widget.weapon.name = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (v) => widget.weapon.description = v,
          ),
        ],
      ),
    );
  }
}

// ---- Armors ----

class _ArmorsTab extends StatefulWidget {
  const _ArmorsTab({required this.db});
  final GameDatabase db;
  @override
  State<_ArmorsTab> createState() => _ArmorsTabState();
}

class _ArmorsTabState extends State<_ArmorsTab> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ListView(
          children: widget.db.armors.map((a) {
            return ListTile(
              title: Text(a.name),
              selected: a.id == _selectedId,
              onTap: () => setState(() => _selectedId = a.id),
            );
          }).toList(),
        ),
      ),
      Expanded(
        flex: 2,
        child: _selectedId == null
            ? const Center(child: Text('Sélectionnez une armure'))
            : _ArmorEditor(armor: widget.db.armors.firstWhere((e) => e.id == _selectedId)),
      ),
    ]);
  }
}

class _ArmorEditor extends StatefulWidget {
  const _ArmorEditor({required this.armor});
  final ArmorData armor;
  @override
  State<_ArmorEditor> createState() => _ArmorEditorState();
}

class _ArmorEditorState extends State<_ArmorEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.armor.name);
    _descCtrl = TextEditingController(text: widget.armor.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => widget.armor.name = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (v) => widget.armor.description = v,
          ),
        ],
      ),
    );
  }
}

// ---- Enemies ----

class _EnemiesTab extends StatefulWidget {
  const _EnemiesTab({required this.db});
  final GameDatabase db;
  @override
  State<_EnemiesTab> createState() => _EnemiesTabState();
}

class _EnemiesTabState extends State<_EnemiesTab> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ListView(
          children: widget.db.enemies.map((e) {
            return ListTile(
              title: Text(e.name),
              selected: e.id == _selectedId,
              onTap: () => setState(() => _selectedId = e.id),
            );
          }).toList(),
        ),
      ),
      Expanded(
        flex: 2,
        child: _selectedId == null
            ? const Center(child: Text('Sélectionnez un ennemi'))
            : _EnemyEditor(enemy: widget.db.enemies.firstWhere((e) => e.id == _selectedId)),
      ),
    ]);
  }
}

class _EnemyEditor extends StatefulWidget {
  const _EnemyEditor({required this.enemy});
  final EnemyData enemy;
  @override
  State<_EnemyEditor> createState() => _EnemyEditorState();
}

class _EnemyEditorState extends State<_EnemyEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.enemy.name);
    _descCtrl = TextEditingController(text: widget.enemy.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => widget.enemy.name = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (v) => widget.enemy.description = v,
          ),
        ],
      ),
    );
  }
}

// ---- Troops ----

class _TroopsTab extends StatefulWidget {
  const _TroopsTab({required this.db});
  final GameDatabase db;
  @override
  State<_TroopsTab> createState() => _TroopsTabState();
}

class _TroopsTabState extends State<_TroopsTab> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ListView(
          children: widget.db.troops.map((t) {
            return ListTile(
              title: Text(t.name),
              selected: t.id == _selectedId,
              onTap: () => setState(() => _selectedId = t.id),
            );
          }).toList(),
        ),
      ),
      Expanded(
        flex: 2,
        child: _selectedId == null
            ? const Center(child: Text('Sélectionnez un groupe'))
            : _TroopEditor(troop: widget.db.troops.firstWhere((e) => e.id == _selectedId)),
      ),
    ]);
  }
}

class _TroopEditor extends StatefulWidget {
  const _TroopEditor({required this.troop});
  final TroopData troop;
  @override
  State<_TroopEditor> createState() => _TroopEditorState();
}

class _TroopEditorState extends State<_TroopEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _membersCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.troop.name);
    _membersCtrl = TextEditingController(text: widget.troop.members.join(','));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _membersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => widget.troop.name = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _membersCtrl,
            decoration: const InputDecoration(labelText: 'Membres (ids séparés par des virgules)'),
            onChanged: (v) {
              widget.troop.members = v.split(',').where((e) => e.trim().isNotEmpty).map((e) => int.tryParse(e.trim()) ?? 0).toList();
            },
          ),
        ],
      ),
    );
  }
}

// ---- States ----

class _StatesTab extends StatefulWidget {
  const _StatesTab({required this.db});
  final GameDatabase db;
  @override
  State<_StatesTab> createState() => _StatesTabState();
}

class _StatesTabState extends State<_StatesTab> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ListView(
          children: widget.db.states.map((s) {
            return ListTile(
              title: Text(s.name),
              selected: s.id == _selectedId,
              onTap: () => setState(() => _selectedId = s.id),
            );
          }).toList(),
        ),
      ),
      Expanded(
        flex: 2,
        child: _selectedId == null
            ? const Center(child: Text('Sélectionnez un état'))
            : _StateEditor(state: widget.db.states.firstWhere((e) => e.id == _selectedId)),
      ),
    ]);
  }
}

class _StateEditor extends StatefulWidget {
  const _StateEditor({required this.state});
  final StateData state;
  @override
  State<_StateEditor> createState() => _StateEditorState();
}

class _StateEditorState extends State<_StateEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.state.name);
    _descCtrl = TextEditingController(text: widget.state.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => widget.state.name = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (v) => widget.state.description = v,
          ),
        ],
      ),
    );
  }
}

// ---- Animations ----

class _AnimationsTab extends StatefulWidget {
  const _AnimationsTab({required this.db});
  final GameDatabase db;
  @override
  State<_AnimationsTab> createState() => _AnimationsTabState();
}

class _AnimationsTabState extends State<_AnimationsTab> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ListView(
          children: widget.db.animations.map((a) {
            return ListTile(
              title: Text(a.name),
              selected: a.id == _selectedId,
              onTap: () => setState(() => _selectedId = a.id),
            );
          }).toList(),
        ),
      ),
      Expanded(
        flex: 2,
        child: _selectedId == null
            ? const Center(child: Text('Sélectionnez une animation'))
            : _AnimationEditor(animation: widget.db.animations.firstWhere((e) => e.id == _selectedId)),
      ),
    ]);
  }
}

class _AnimationEditor extends StatefulWidget {
  const _AnimationEditor({required this.animation});
  final AnimationData animation;
  @override
  State<_AnimationEditor> createState() => _AnimationEditorState();
}

class _AnimationEditorState extends State<_AnimationEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.animation.name);
    _descCtrl = TextEditingController(text: widget.animation.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => widget.animation.name = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (v) => widget.animation.description = v,
          ),
        ],
      ),
    );
  }
}

