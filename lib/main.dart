// ignore_for_file: prefer_const_constructors, avoid_print

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart' as dmw;
import 'map_editor.dart';
import 'models.dart';
import 'scene_editor.dart';
import 'runtime.dart';

// CameraMode is now defined in models.dart

/// Représente une statistique de base définie par l'utilisateur ou par défaut.
class StatDef {
  final String name;
  String meaning;
  List<String> affects;
  StatDef(this.name, {this.meaning = '', List<String>? affects})
      : affects = affects ?? [];
}

/// Définit un état (buff ou malus) avec type et description.
class StateDef {
  final String name;
  String type; // Buff ou Malus
  String effect;
  StateDef(this.name, {this.type = 'Buff', this.effect = ''});
}

/// Définit un projectile avec versions 2D et 3D, vitesse et gravité.
class ProjectileDef {
  final String name;
  String twoDAsset;
  String threeDAsset;
  double speed;
  double gravity;
  ProjectileDef(this.name,
      {this.twoDAsset = '', this.threeDAsset = '', this.speed = 10, this.gravity = 0});
}

/// Animation utilisée pour les déplacements ou actions d'un personnage.
class ActorAnimationDef {
  final String name;
  String asset2D;
  String asset3D;
  ActorAnimationDef(this.name, {this.asset2D = '', this.asset3D = ''});
}

/// Animation d'effet visuel (VFX) compatible 2D et 3D.
class VfxAnimationDef {
  final String name;
  String asset2D;
  String asset3D;
  VfxAnimationDef(this.name, {this.asset2D = '', this.asset3D = ''});
}

/// Définit une classe de personnage (statistiques de base).
class ClassDef {
  ClassDef(this.name, {Map<String, double>? baseStats, this.description = ''})
      : baseStats = baseStats ?? {};
  final String name;
  String description;
  final Map<String, double> baseStats;
}

/// Décrit un tileset avec listes d'assets 2D et 3D.
class TilesetDef {
  TilesetDef(this.name, {List<String>? assets2D, List<String>? assets3D})
      : assets2D = assets2D ?? [],
        assets3D = assets3D ?? [];
  final String name;
  final List<String> assets2D;
  final List<String> assets3D;
}

/// Définit un personnage (héros ou ennemi) avec statistiques, résistances et états appliqués.
class EntityDef {
  String name;
  Map<String, double> stats;
  Map<String, double> resistances;
  Set<String> states;
  EntityDef({required this.name, Map<String, double>? stats, Map<String, double>? resistances, Set<String>? states})
      : stats = stats ?? {},
        resistances = resistances ?? {},
        states = states ?? {};
}

/// Point d'entrée de l'application.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Arguments éventuels pour les fenêtres secondaires.
  Map<String, dynamic> windowArgs = {};
  if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
    try {
      if (args.isNotEmpty && args.first == 'multi_window') {
        final jsonStr = (args.length > 2) ? args[2] : '';
        if (jsonStr.isNotEmpty) {
          windowArgs = jsonDecode(jsonStr) as Map<String, dynamic>;
          windowArgs['__windowId'] = int.tryParse(args.elementAt(1)) ?? 0;
        }
      }
    } catch (_) {}
  }

  runApp(EditorApp(isSubWindow: windowArgs['role'] == 'database'));
}

/// Application principale.
class EditorApp extends StatelessWidget {
  const EditorApp({super.key, required this.isSubWindow});
  final bool isSubWindow;

  // Thème bleu inspiré d'éditeurs classiques sans référence explicite.
  ThemeData _blueHudTheme() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2377D0),
        brightness: Brightness.light,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFE8F0FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E6CB8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFFF5F9FF),
      dividerColor: const Color(0xFFB7D3F8),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFE0ECFF),
        labelStyle: const TextStyle(color: Color(0xFF0F3157)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF0F3157),
        textColor: Color(0xFF0F3157),
        selectedTileColor: Color(0xFFD1E6FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memoria Editor',
      debugShowCheckedModeBanner: false,
      theme: _blueHudTheme(),
      home: isSubWindow ? const DatabaseWindow() : const MainWindow(),
    );
  }
}

/// Fenêtre principale avec scène et palettes.
class MainWindow extends StatefulWidget {
  const MainWindow({super.key});
  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  // Mode de caméra par défaut du projet.
  CameraMode projectDefaultMode = CameraMode.twoPointFiveD;
  // Liste des cartes avec leurs modes individuels.
  final List<Map<String, dynamic>> maps = [
    {'name': 'Map001', 'mode': CameraMode.twoPointFiveD},
    {'name': 'Map002', 'mode': CameraMode.twoPointFiveD},
    {'name': 'Map003', 'mode': CameraMode.twoPointFiveD},
  ];
  int selectedMapIndex = 0;
  // Ensemble d'assets disponibles (2D et 3D) ; ici en exemple.
  final Map<String, AssetKind2D> twoDAssets = {
    'Hero.png': AssetKind2D.sprite,
    'ForestTiles.png': AssetKind2D.tile,
    'Slime.png': AssetKind2D.sprite,
    'Arrow.asset': AssetKind2D.projectile2D,
    'Dust.pfx': AssetKind2D.particles,
  };
  final Map<String, AssetKind3D> threeDAssets = {
    'Hero.glb': AssetKind3D.model,
    'Goblin.glb': AssetKind3D.model,
    'Terrain.fbx': AssetKind3D.mesh,
    'Arrow3D.asset': AssetKind3D.projectile3D,
    'Muzzle.vfx': AssetKind3D.vfx,
  };
  // Objets placés dans la scène (nom uniquement).
     final List<String> placed = [];
   final Map<String, MapData> _mapNameToData = {};
   final Map<String, SceneData> _mapNameToScene = {};
   int editorTabIndex = 0; // 0: Carte, 1: Scène
   String? pendingAssetToPlace;

   MapData _ensureMapData(String name) {
     return _mapNameToData.putIfAbsent(name, () => MapData(name: name, width: 50, height: 30));
   }

   SceneData _ensureSceneData(String name) {
     return _mapNameToScene.putIfAbsent(name, () => SceneData(name: name));
   }

  @override
  Widget build(BuildContext context) {
    // Mode caméra actuel basé sur la carte sélectionnée.
    final CameraMode camera = maps[selectedMapIndex]['mode'] as CameraMode;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _BlueHudBar(
          title: 'Memoria Editor — Main',
          actions: [
            // Sélecteur du mode prédominant du projet
            Row(
              children: [
                const Text('Mode projet :', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 4),
                DropdownButton<CameraMode>(
                  value: projectDefaultMode,
                  dropdownColor: const Color(0xFF1E6CB8),
                  style: const TextStyle(color: Colors.white),
                  underline: Container(height: 0),
                  items: CameraMode.values.map((m) {
                    return DropdownMenuItem(value: m, child: Text(describeEnum(m)));
                  }).toList(),
                  onChanged: (m) {
                    if (m != null) {
                      setState(() {
                        projectDefaultMode = m;
                        // Mettre à jour toutes les cartes qui n'ont pas été modifiées.
                        for (final map in maps) {
                          map['mode'] = m;
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Base de données',
              onPressed: _openDatabaseWindow,
              icon: const Icon(Icons.storage_outlined, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 320,
            child: Column(
              children: [
                const _SectionHeader(label: 'Cartes'),
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: ListView.builder(
                      itemCount: maps.length,
                      itemBuilder: (_, i) {
                        final map = maps[i];
                        return ListTile(
                          leading: const Icon(Icons.map_outlined),
                          title: Text(map['name'] as String),
                          selected: i == selectedMapIndex,
                          subtitle: DropdownButton<CameraMode>(
                            value: map['mode'] as CameraMode,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black),
                            underline: Container(height: 0),
                            items: CameraMode.values.map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text(describeEnum(m)),
                              );
                            }).toList(),
                            onChanged: (m) {
                              if (m != null) {
                                setState(() => map['mode'] = m);
                              }
                            },
                          ),
                          onTap: () => setState(() => selectedMapIndex = i),
                        );
                      },
                    ),
                  ),
                ),
                const _SectionHeader(label: 'Assets'),
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: _AssetList(
                      camera: camera,
                      twoD: twoDAssets,
                      threeD: threeDAssets,
                      onUse: (name) => setState(() { pendingAssetToPlace = name; editorTabIndex = 1; }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
                     Expanded(
             child: Column(
               children: [
                 _SectionHeader(label: 'Édition — ${maps[selectedMapIndex]['name']}'),
                 Container(
                   color: const Color(0xFF0F2F59),
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                   child: Row(
                     children: [
                       SegmentedButton<int>(
                         segments: const [
                           ButtonSegment<int>(value: 0, label: Text('Carte')),
                           ButtonSegment<int>(value: 1, label: Text('Scène')),
                         ],
                         selected: {editorTabIndex},
                         onSelectionChanged: (s) => setState(() => editorTabIndex = s.first),
                       ),
                       const SizedBox(width: 12),
                       FilledButton.icon(
                         onPressed: () {
                           final name = maps[selectedMapIndex]['name'] as String;
                           final mapData = _ensureMapData(name);
                           final sceneData = _ensureSceneData(name);
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (_) => RuntimePreviewPage(
                                 mapData: mapData,
                                 scene: sceneData,
                                 cameraMode: (maps[selectedMapIndex]['mode'] as CameraMode),
                               ),
                             ),
                           );
                         },
                         icon: const Icon(Icons.play_arrow),
                         label: const Text('Jouer'),
                       ),
                     ],
                   ),
                 ),
                 Expanded(
                   child: Container(
                     decoration: const BoxDecoration(
                       gradient: LinearGradient(
                         colors: [Color(0xFF0B3D75), Color(0xFF05284D)],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                     ),
                     child: editorTabIndex == 0
                         ? MapEditorPage(
                             mapData: _ensureMapData(maps[selectedMapIndex]['name'] as String),
                           )
                         : SceneEditorPage(
                             scene: _ensureSceneData(maps[selectedMapIndex]['name'] as String),
                             mapData: _ensureMapData(maps[selectedMapIndex]['name'] as String),
                             cameraMode: (maps[selectedMapIndex]['mode'] as CameraMode),
                             pendingAssetName: pendingAssetToPlace,
                             onPendingAssetConsumed: () => setState(() => pendingAssetToPlace = null),
                           ),
                   ),
                 ),
                Container(
                  height: 26,
                  color: const Color(0xFF1E6CB8),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Statut : ${pendingAssetToPlace != null ? 'Placement en attente: $pendingAssetToPlace' : 'prêt'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDatabaseWindow() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DatabaseWindow()));
      return;
    }
    try {
      final window = await dmw.DesktopMultiWindow.createWindow(jsonEncode({'role': 'database'}));
      await window.setTitle('Memoria Editor — Database');
      await window.setFrame(const Offset(120, 120) & const Size(1150, 760));
      await window.center();
      await window.show();
    } catch (_) {}
  }
}

/// Liste d'assets selon le mode de caméra.
class _AssetList extends StatelessWidget {
  const _AssetList({required this.camera, required this.twoD, required this.threeD, required this.onUse});
  final CameraMode camera;
  final Map<String, AssetKind2D> twoD;
  final Map<String, AssetKind3D> threeD;
  final ValueChanged<String> onUse;
  @override
  Widget build(BuildContext context) {
    final is3D = camera == CameraMode.threeD;
    final entries = is3D ? threeD.entries : twoD.entries;
    return ListView(
      children: [
        for (final e in entries)
          ListTile(
            leading: Icon(is3D ? Icons.view_in_ar : Icons.image_outlined),
            title: Text(e.key),
            subtitle: Text(describeEnum(e.value)),
            trailing: FilledButton(
              onPressed: () => onUse(e.key),
              child: const Text('Placer'),
            ),
          ),
      ],
    );
  }
}

/// Fenêtre de base de données avec onglets.
class DatabaseWindow extends StatefulWidget {
  const DatabaseWindow({super.key});
  @override
  State<DatabaseWindow> createState() => _DatabaseWindowState();
}

class _DatabaseWindowState extends State<DatabaseWindow> {
  @override
  Widget build(BuildContext context) {
    final tabs = <_DbTab>[
      _DbTab('Héros', Icons.person_outline, const ActorsTab()),
      _DbTab('Classes', Icons.school_outlined, const ClassesTab()),
      _DbTab('Ennemis', Icons.android_outlined, const EnemiesTab()),
      _DbTab('Tilesets', Icons.grid_on_outlined, const TilesetsTab()),
      _DbTab('Objets', Icons.backpack_outlined, const ItemsTab()),
      _DbTab('Compétences', Icons.auto_fix_high_outlined, const SkillsTab()),
      _DbTab('États', Icons.healing_outlined, const StatesTab()),
      _DbTab('Système', Icons.settings_outlined, const SystemTab()),
      _DbTab('Stats', Icons.bar_chart, const StatsDesignerTab()),
      _DbTab('Projectiles', Icons.bolt_outlined, const ProjectilesTab()),
      _DbTab('Anim. Acteur', Icons.directions_run, const ActorAnimationsTab()),
      _DbTab('Anim. VFX', Icons.auto_awesome, const VfxAnimationsTab()),
      _DbTab('Template', Icons.file_copy_outlined, const TemplateTab()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              const _BlueHudBar(title: 'Base de données'),
              Container(
                color: const Color(0xFF165A9A),
                child: TabBar(
                  isScrollable: true,
                  tabs: [for (final t in tabs) Tab(text: t.label, icon: Icon(t.icon))],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(children: [for (final t in tabs) t.page]),
      ),
    );
  }
}

class _DbTab {
  final String label;
  final IconData icon;
  final Widget page;
  const _DbTab(this.label, this.icon, this.page);
}

// ==================== TABS PLACEHOLDERS & ÉDITEURS ====================

// Acteurs (héros)
class ActorsTab extends StatefulWidget {
  const ActorsTab({super.key});
  @override
  State<ActorsTab> createState() => _ActorsTabState();
}

class _ActorsTabState extends State<ActorsTab> {
  // Liste d'acteurs par défaut (dérivés d'Excellion_Nomenclature)
  final Map<String, EntityDef> actors = {
    'Alister': EntityDef(name: 'Alister', stats: {
      'HP': 150,
      'MP': 80,
      'HG': 100,
      'Atk': 12,
      'Def': 10,
      'MAtk': 8,
      'MDef': 9,
      'AtkSpeed': 100,
      'MoveSpeed': 4,
      'JumpHeight': 2,
      'CriticalHit': 5,
    }),
    'Hitomi': EntityDef(name: 'Hitomi', stats: {
      'HP': 120,
      'MP': 120,
      'HG': 100,
      'Atk': 10,
      'Def': 8,
      'MAtk': 12,
      'MDef': 10,
      'AtkSpeed': 110,
      'MoveSpeed': 4,
      'JumpHeight': 2,
      'CriticalHit': 6,
    }),
    'Steem': EntityDef(name: 'Steem', stats: {
      'HP': 160,
      'MP': 60,
      'HG': 120,
      'Atk': 14,
      'Def': 12,
      'MAtk': 6,
      'MDef': 7,
      'AtkSpeed': 90,
      'MoveSpeed': 3,
      'JumpHeight': 2,
      'CriticalHit': 4,
    }),
    'Yann': EntityDef(name: 'Yann', stats: {
      'HP': 140,
      'MP': 90,
      'HG': 110,
      'Atk': 11,
      'Def': 9,
      'MAtk': 10,
      'MDef': 11,
      'AtkSpeed': 105,
      'MoveSpeed': 5,
      'JumpHeight': 3,
      'CriticalHit': 7,
    }),
    'Lirine': EntityDef(name: 'Lirine', stats: {
      'HP': 130,
      'MP': 110,
      'HG': 100,
      'Atk': 9,
      'Def': 8,
      'MAtk': 13,
      'MDef': 12,
      'AtkSpeed': 115,
      'MoveSpeed': 4,
      'JumpHeight': 2,
      'CriticalHit': 6,
    }),
  };
  String? selected;
  @override
  Widget build(BuildContext context) {
    final states = _defaultStates;
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(12),
            child: ListView(
              children: actors.keys.map((name) {
                final isSelected = name == selected;
                return ListTile(
                  title: Text(name),
                  selected: isSelected,
                  onTap: () => setState(() => selected = name),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Card(
            margin: const EdgeInsets.all(12),
            child: selected == null
                ? const Center(child: Text('Sélectionnez un héros pour éditer'))
                : _ActorEditor(
                    actor: actors[selected]!,
                    availableStates: states,
                    onChanged: () => setState(() {}),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ActorEditor extends StatefulWidget {
  final EntityDef actor;
  final Map<String, StateDef> availableStates;
  final VoidCallback onChanged;
  const _ActorEditor({required this.actor, required this.availableStates, required this.onChanged});
  @override
  State<_ActorEditor> createState() => _ActorEditorState();
}

class _ActorEditorState extends State<_ActorEditor> {
  late final Map<String, TextEditingController> _controllers;
  @override
  void initState() {
    super.initState();
    _controllers = {};
    widget.actor.stats.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value.toString());
    });
  }
  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Héros : ${widget.actor.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Statistiques de base:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.actor.stats.keys.map((stat) {
                final ctrl = _controllers[stat]!;
                return SizedBox(
                  width: 160,
                  child: TextField(
                    controller: ctrl,
                    decoration: InputDecoration(
                      labelText: stat,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      widget.actor.stats[stat] = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('États appliqués:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: widget.availableStates.keys.map((s) {
                final has = widget.actor.states.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: has,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        widget.actor.states.add(s);
                      } else {
                        widget.actor.states.remove(s);
                      }
                      widget.onChanged();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                // Eventuelle sauvegarde : ici on ne fait que mettre à jour l'état local.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Statistiques et états enregistrés')),);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

// Classes
class ClassesTab extends StatefulWidget {
  const ClassesTab({super.key});
  @override
  State<ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<ClassesTab> {
  final Map<String, ClassDef> classes = {
    'Guerrier': ClassDef('Guerrier', baseStats: {
      'HP': 110,
      'MP': 20,
      'Atk': 15,
      'Def': 12,
    }),
    'Mage': ClassDef('Mage', baseStats: {
      'HP': 80,
      'MP': 150,
      'Atk': 8,
      'Def': 6,
    }),
  };
  String? selected;
  @override
  Widget build(BuildContext context) {
    final stats = ['HP', 'MP', 'Atk', 'Def', 'MAtk', 'MDef'];
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(12),
            child: ListView(
              children: classes.keys.map((name) {
                final isSelected = name == selected;
                return ListTile(
                  title: Text(name),
                  selected: isSelected,
                  onTap: () => setState(() => selected = name),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Card(
            margin: const EdgeInsets.all(12),
            child: selected == null
                ? const Center(child: Text('Sélectionnez une classe pour éditer'))
                : _ClassEditor(
                    classDef: classes[selected]!,
                    stats: stats,
                    onChanged: () => setState(() {}),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ClassEditor extends StatefulWidget {
  final ClassDef classDef;
  final List<String> stats;
  final VoidCallback onChanged;
  const _ClassEditor(
      {required this.classDef, required this.stats, required this.onChanged});
  @override
  State<_ClassEditor> createState() => _ClassEditorState();
}

class _ClassEditorState extends State<_ClassEditor> {
  late final Map<String, TextEditingController> _controllers;
  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final s in widget.stats)
        s: TextEditingController(
            text: widget.classDef.baseStats[s]?.toString() ?? '0')
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    widget.classDef.baseStats.clear();
    _controllers.forEach((k, c) {
      widget.classDef.baseStats[k] = double.tryParse(c.text) ?? 0;
    });
    widget.onChanged();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Classe enregistrée')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Classe : ${widget.classDef.name}',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.stats.map((stat) {
              final ctrl = _controllers[stat]!;
              return SizedBox(
                width: 160,
                child: TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    labelText: stat,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

// Ennemis
class EnemiesTab extends StatefulWidget {
  const EnemiesTab({super.key});
  @override
  State<EnemiesTab> createState() => _EnemiesTabState();
}

class _EnemiesTabState extends State<EnemiesTab> {
  final Map<String, EntityDef> enemies = {
    'Slime': EntityDef(name: 'Slime', stats: {
      'HP': 60,
      'MP': 0,
      'HG': 50,
      'Atk': 6,
      'Def': 3,
      'MAtk': 2,
      'MDef': 2,
      'AtkSpeed': 80,
      'MoveSpeed': 2,
      'JumpHeight': 1,
      'CriticalHit': 2,
    }),
    'Goblin': EntityDef(name: 'Goblin', stats: {
      'HP': 80,
      'MP': 0,
      'HG': 60,
      'Atk': 8,
      'Def': 4,
      'MAtk': 3,
      'MDef': 3,
      'AtkSpeed': 90,
      'MoveSpeed': 3,
      'JumpHeight': 1,
      'CriticalHit': 3,
    }),
    'Orc': EntityDef(name: 'Orc', stats: {
      'HP': 120,
      'MP': 0,
      'HG': 70,
      'Atk': 12,
      'Def': 5,
      'MAtk': 2,
      'MDef': 3,
      'AtkSpeed': 70,
      'MoveSpeed': 2,
      'JumpHeight': 1,
      'CriticalHit': 2,
    }),
  };
  String? selected;
  @override
  Widget build(BuildContext context) {
    final states = _defaultStates;
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(12),
            child: ListView(
              children: enemies.keys.map((name) {
                final isSelected = name == selected;
                return ListTile(
                  title: Text(name),
                  selected: isSelected,
                  onTap: () => setState(() => selected = name),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Card(
            margin: const EdgeInsets.all(12),
            child: selected == null
                ? const Center(child: Text('Sélectionnez un ennemi pour éditer'))
                : _ActorEditor(
                    actor: enemies[selected]!,
                    availableStates: states,
                    onChanged: () => setState(() {}),
                  ),
          ),
        ),
      ],
    );
  }
}

// Tilesets (placeholders)
class TilesetsTab extends StatefulWidget {
  const TilesetsTab({super.key});
  @override
  State<TilesetsTab> createState() => _TilesetsTabState();
}

class _TilesetsTabState extends State<TilesetsTab> {
  final List<TilesetDef> tilesets = [
    TilesetDef('Forêt', assets2D: ['forest.png'], assets3D: ['forest.glb']),
    TilesetDef('Donjon', assets2D: ['dungeon.png'], assets3D: ['dungeon.glb']),
  ];
  final _nameCtrl = TextEditingController();
  final _a2dCtrl = TextEditingController();
  final _a3dCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _a2dCtrl.dispose();
    _a3dCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _pad(Card(
            child: Column(
              children: [
                const _Subheader('Tilesets'),
                Expanded(
                  child: ListView.builder(
                    itemCount: tilesets.length,
                    itemBuilder: (_, i) {
                      final t = tilesets[i];
                      return ListTile(
                        leading: const Icon(Icons.grid_on_outlined),
                        title: Text(t.name),
                        subtitle: Text('2D: ${t.assets2D.length} — 3D: ${t.assets3D.length}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          )),
        ),
        Expanded(
          child: _pad(Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Subheader('Créer / éditer'),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom')),
                  TextField(controller: _a2dCtrl, decoration: const InputDecoration(labelText: 'Assets 2D (séparés par des virgules)')),
                  TextField(controller: _a3dCtrl, decoration: const InputDecoration(labelText: 'Assets 3D (séparés par des virgules)')),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        tilesets.add(TilesetDef(
                          _nameCtrl.text.trim(),
                          assets2D: _a2dCtrl.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                          assets3D: _a3dCtrl.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                        ));
                        _nameCtrl.clear();
                        _a2dCtrl.clear();
                        _a3dCtrl.clear();
                      });
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer le tileset'),
                  ),
                ],
              ),
            ),
          )),
        ),
      ],
    );
  }
}

class ItemsTab extends StatelessWidget {
  const ItemsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Éditeur d’objets (à implémenter)'));
  }
}

class SkillsTab extends StatelessWidget {
  const SkillsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Éditeur de compétences (à implémenter)'));
  }
}

// États (buffs/malus) à partir de Système du jeu
class StatesTab extends StatefulWidget {
  const StatesTab({super.key});
  @override
  State<StatesTab> createState() => _StatesTabState();
}

class _StatesTabState extends State<StatesTab> {
  final Map<String, StateDef> states = Map.from(_defaultStates);
  final Map<String, Set<String>> assignments = {
    'Héros': <String>{},
    'Ennemis': <String>{},
  };
  final _nameCtrl = TextEditingController();
  String _type = 'Buff';
  final _effectCtrl = TextEditingController();
  @override
  void dispose() {
    _nameCtrl.dispose();
    _effectCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _pad(Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Subheader('États définis'),
                Expanded(
                  child: ListView(
                    children: states.values.map((s) => ListTile(
                      title: Text(s.name),
                      subtitle: Text('${s.type} — ${s.effect}'),
                    )).toList(),
                  ),
                ),
              ],
            ),
          )),
        ),
        Expanded(
          child: _pad(Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Subheader('Créer / éditer un état'),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom')), 
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: _type,
                    items: const [DropdownMenuItem(value: 'Buff', child: Text('Buff')), DropdownMenuItem(value: 'Malus', child: Text('Malus'))],
                    onChanged: (v) => setState(() => _type = v ?? 'Buff'),
                  ),
                  TextField(controller: _effectCtrl, decoration: const InputDecoration(labelText: 'Effet (description)')),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      final name = _nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setState(() {
                        states[name] = StateDef(name, type: _type, effect: _effectCtrl.text.trim());
                        _nameCtrl.clear();
                        _effectCtrl.clear();
                      });
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer l’état'),
                  ),
                ],
              ),
            ),
          )),
        ),
        Expanded(
          child: _pad(Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Subheader('Attribuer aux entités'),
                Expanded(
                  child: ListView(
                    children: assignments.keys.map((entityType) {
                      final assigned = assignments[entityType]!;
                      return ExpansionTile(
                        title: Text(entityType),
                        children: states.keys.map((s) {
                          final has = assigned.contains(s);
                          return CheckboxListTile(
                            title: Text(s),
                            value: has,
                            onChanged: (v) {
                              setState(() {
                                if (v ?? false) {
                                  assigned.add(s);
                                } else {
                                  assigned.remove(s);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          )),
        ),
      ],
    );
  }
}

// Système (autres paramètres généraux)
class SystemTab extends StatelessWidget {
  const SystemTab({super.key});
  @override
  Widget build(BuildContext context) {
    return _pad(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paramètres du système', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ici vous pouvez configurer les paramètres généraux (sons, polices, variables globales, etc.).'),
        ],
      ),
    );
  }
}

// Stats Designer (gestion des statistiques)
class StatsDesignerTab extends StatefulWidget {
  const StatsDesignerTab({super.key});
  @override
  State<StatsDesignerTab> createState() => _StatsDesignerTabState();
}

class _StatsDesignerTabState extends State<StatsDesignerTab> {
  final Map<String, StatDef> stats = {
    'HP': StatDef('HP', meaning: 'Points de vie', affects: ['Barre de vie']),
    'MP': StatDef('MP', meaning: 'Points de capacité', affects: ['Barre de capacité']),
    'HG': StatDef('HG', meaning: 'Endurance', affects: ['Barre d’endurance', 'Vitesse de déplacement']),
    'Atk': StatDef('Atk', meaning: 'Attaque physique', affects: ['Dégâts physiques']),
    'Def': StatDef('Def', meaning: 'Défense physique', affects: ['Réduction des dégâts physiques']),
    'MAtk': StatDef('MAtk', meaning: 'Attaque magique', affects: ['Dégâts magiques']),
    'MDef': StatDef('MDef', meaning: 'Défense magique', affects: ['Réduction des dégâts magiques']),
    'AtkSpeed': StatDef('AtkSpeed', meaning: 'Vitesse d’attaque', affects: ['Cadence d’attaque']),
    'MoveSpeed': StatDef('MoveSpeed', meaning: 'Vitesse de déplacement', affects: ['Rapidité du personnage']),
    'JumpHeight': StatDef('JumpHeight', meaning: 'Hauteur de saut', affects: ['Saut du personnage']),
    'CriticalHit': StatDef('CriticalHit', meaning: 'Probabilité de coup critique', affects: ['Taux de critique']),
    'PoisonResist': StatDef('PoisonResist', meaning: 'Résistance au poison', affects: ['Réduction des dégâts poison']),
    'MuteResist': StatDef('MuteResist', meaning: 'Résistance au silence', affects: ['Réduction du silence']),
    'StunResist': StatDef('StunResist', meaning: 'Résistance à l’étourdissement', affects: ['Réduction de l’étourdissement']),
    'ParalyzeResist': StatDef('ParalyzeResist', meaning: 'Résistance à la paralysie', affects: ['Réduction de paralysie']),
    'BlindResist': StatDef('BlindResist', meaning: 'Résistance à l’aveuglement', affects: ['Réduction de précision due à l’aveuglement']),
    'ConfuseResist': StatDef('ConfuseResist', meaning: 'Résistance à la confusion', affects: ['Réduction de confusion']),
    'SlowResist': StatDef('SlowResist', meaning: 'Résistance au ralentissement', affects: ['Réduction de la lenteur']),
    'InjuryResist': StatDef('InjuryResist', meaning: 'Résistance à la blessure', affects: ['Réduction des blessures']),
    'CurseResist': StatDef('CurseResist', meaning: 'Résistance à la malédiction', affects: ['Réduction de la malédiction']),
    'CosmosResist': StatDef('CosmosResist', meaning: 'Résistance au cosmos', affects: ['Réduction de dégâts cosmiques']),
    'ModifierResist': StatDef('ModifierResist', meaning: 'Résistance au modificateur', affects: ['Réduction des modificateurs']),
    'FireAffinity': StatDef('FireAffinity', meaning: 'Affinité feu', affects: ['Dégâts élément feu']),
    'WaterAffinity': StatDef('WaterAffinity', meaning: 'Affinité eau', affects: ['Dégâts élément eau']),
    'WindAffinity': StatDef('WindAffinity', meaning: 'Affinité vent', affects: ['Dégâts élément vent']),
    'EarthAffinity': StatDef('EarthAffinity', meaning: 'Affinité terre', affects: ['Dégâts élément terre']),
    'LightAffinity': StatDef('LightAffinity', meaning: 'Affinité lumière', affects: ['Dégâts élément lumière']),
    'DarkAffinity': StatDef('DarkAffinity', meaning: 'Affinité ténèbres', affects: ['Dégâts élément ténèbres']),
  };
  final Map<String, Set<String>> assignments = {
    'Héros': <String>{'HP','MP','HG','Atk','Def','MAtk','MDef','AtkSpeed','MoveSpeed','JumpHeight','CriticalHit'},
    'Ennemis': <String>{'HP','HG','Atk','Def','AtkSpeed','MoveSpeed'},
  };
  final _nameCtrl = TextEditingController();
  final _meaningCtrl = TextEditingController();
  final _affectCtrl = TextEditingController();
  @override
  void dispose() {
    _nameCtrl.dispose();
    _meaningCtrl.dispose();
    _affectCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _pad(Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Subheader('Statistiques définies'),
                Expanded(
                  child: ListView(
                    children: stats.values.map((s) => ListTile(
                      title: Text(s.name),
                      subtitle: Text('${s.meaning} — affects : ${s.affects.join(', ')}'),
                    )).toList(),
                  ),
                ),
              ],
            ),
          )),
        ),
        Expanded(
          child: _pad(Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Subheader('Créer / éditer une stat'),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom')), 
                  TextField(controller: _meaningCtrl, decoration: const InputDecoration(labelText: 'Sens / comportement')),
                  TextField(controller: _affectCtrl, decoration: const InputDecoration(labelText: 'Influence (séparée par des virgules)')),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      final name = _nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setState(() {
                        stats[name] = StatDef(
                          name,
                          meaning: _meaningCtrl.text.trim(),
                          affects: _affectCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                        );
                        _nameCtrl.clear();
                        _meaningCtrl.clear();
                        _affectCtrl.clear();
                      });
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer la stat'),
                  ),
                ],
              ),
            ),
          )),
        ),
        Expanded(
          child: _pad(Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Subheader('Attribuer aux entités'),
                Expanded(
                  child: ListView(
                    children: assignments.keys.map((entityType) {
                      final assigned = assignments[entityType]!;
                      return ExpansionTile(
                        title: Text(entityType),
                        children: stats.keys.map((s) {
                          final has = assigned.contains(s);
                          return CheckboxListTile(
                            title: Text(s),
                            value: has,
                            onChanged: (v) {
                              setState(() {
                                if (v ?? false) {
                                  assigned.add(s);
                                } else {
                                  assigned.remove(s);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          )),
        ),
      ],
    );
  }
}

// Projectiles Tab
class ProjectilesTab extends StatefulWidget {
  const ProjectilesTab({super.key});
  @override
  State<ProjectilesTab> createState() => _ProjectilesTabState();
}

class _ProjectilesTabState extends State<ProjectilesTab> {
  final List<ProjectileDef> list = [
    ProjectileDef('Arrow', twoDAsset: 'Arrow.asset', threeDAsset: 'Arrow3D.asset', speed: 12, gravity: 0.0),
    ProjectileDef('Fireball', twoDAsset: 'Fireball.asset', threeDAsset: 'Fireball3D.asset', speed: 10, gravity: 0.0),
    ProjectileDef('IceShard', twoDAsset: 'IceShard.asset', threeDAsset: 'IceShard3D.asset', speed: 8, gravity: 0.0),
  ];
  final _nameCtrl = TextEditingController();
  final _a2d = TextEditingController();
  final _a3d = TextEditingController();
  final _spd = TextEditingController(text: '10');
  final _grav = TextEditingController(text: '0');
  @override
  void dispose() {
    _nameCtrl.dispose();
    _a2d.dispose();
    _a3d.dispose();
    _spd.dispose();
    _grav.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _pad(Card(
            child: Column(
              children: [
                const _Subheader('Projectiles définis'),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return ListTile(
                        leading: const Icon(Icons.bolt_outlined),
                        title: Text(p.name),
                        subtitle: Text('2D : ${p.twoDAsset} — 3D : ${p.threeDAsset} — vitesse : ${p.speed} — gravité : ${p.gravity}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          )),
        ),
        Expanded(
          child: _pad(Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Subheader('Créer / éditer un projectile'),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom')),
                  TextField(controller: _a2d, decoration: const InputDecoration(labelText: 'Asset 2D')),
                  TextField(controller: _a3d, decoration: const InputDecoration(labelText: 'Asset 3D')),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _spd, decoration: const InputDecoration(labelText: 'Vitesse'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _grav, decoration: const InputDecoration(labelText: 'Gravité'), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        list.add(ProjectileDef(
                          _nameCtrl.text.trim(),
                          twoDAsset: _a2d.text.trim(),
                          threeDAsset: _a3d.text.trim(),
                          speed: double.tryParse(_spd.text) ?? 10,
                          gravity: double.tryParse(_grav.text) ?? 0,
                        ));
                        _nameCtrl.clear();
                        _a2d.clear();
                        _a3d.clear();
                        _spd.text = '10';
                        _grav.text = '0';
                      });
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer le projectile'),
                  ),
                ],
              ),
            ),
          )),
        ),
      ],
    );
  }
}

class ActorAnimationsTab extends StatefulWidget {
  const ActorAnimationsTab({super.key});
  @override
  State<ActorAnimationsTab> createState() => _ActorAnimationsTabState();
}

class _ActorAnimationsTabState extends State<ActorAnimationsTab> {
  final List<ActorAnimationDef> list = [
    ActorAnimationDef('Marche', asset2D: 'hero_walk.png', asset3D: 'HeroWalk.anim'),
    ActorAnimationDef('Attaque', asset2D: 'hero_attack.png', asset3D: 'HeroAttack.anim'),
  ];
  final _nameCtrl = TextEditingController();
  final _a2d = TextEditingController();
  final _a3d = TextEditingController();
  @override
  void dispose() {
    _nameCtrl.dispose();
    _a2d.dispose();
    _a3d.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _pad(Card(
            child: Column(
              children: [
                const _Subheader('Animations d\'acteur'),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final a = list[i];
                      return ListTile(
                        leading: const Icon(Icons.directions_run),
                        title: Text(a.name),
                        subtitle: Text('2D : ${a.asset2D} — 3D : ${a.asset3D}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          )),
        ),
        Expanded(
          child: _pad(Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Subheader('Créer / éditer'),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom')),
                  TextField(controller: _a2d, decoration: const InputDecoration(labelText: 'Asset 2D')),
                  TextField(controller: _a3d, decoration: const InputDecoration(labelText: 'Asset 3D')),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        list.add(ActorAnimationDef(
                          _nameCtrl.text.trim(),
                          asset2D: _a2d.text.trim(),
                          asset3D: _a3d.text.trim(),
                        ));
                        _nameCtrl.clear();
                        _a2d.clear();
                        _a3d.clear();
                      });
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer l\'animation'),
                  ),
                ],
              ),
            ),
          )),
        ),
      ],
    );
  }
}

class VfxAnimationsTab extends StatefulWidget {
  const VfxAnimationsTab({super.key});
  @override
  State<VfxAnimationsTab> createState() => _VfxAnimationsTabState();
}

class _VfxAnimationsTabState extends State<VfxAnimationsTab> {
  final List<VfxAnimationDef> list = [
    VfxAnimationDef('Explosion', asset2D: 'explosion.pfx', asset3D: 'Explosion3D.vfx'),
    VfxAnimationDef('Soin', asset2D: 'heal.pfx', asset3D: 'Heal3D.vfx'),
  ];
  final _nameCtrl = TextEditingController();
  final _a2d = TextEditingController();
  final _a3d = TextEditingController();
  @override
  void dispose() {
    _nameCtrl.dispose();
    _a2d.dispose();
    _a3d.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _pad(Card(
            child: Column(
              children: [
                const _Subheader('Animations VFX'),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final a = list[i];
                      return ListTile(
                        leading: const Icon(Icons.auto_awesome),
                        title: Text(a.name),
                        subtitle: Text('2D : ${a.asset2D} — 3D : ${a.asset3D}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          )),
        ),
        Expanded(
          child: _pad(Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Subheader('Créer / éditer'),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom')),
                  TextField(controller: _a2d, decoration: const InputDecoration(labelText: 'Asset 2D')),
                  TextField(controller: _a3d, decoration: const InputDecoration(labelText: 'Asset 3D')),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        list.add(VfxAnimationDef(
                          _nameCtrl.text.trim(),
                          asset2D: _a2d.text.trim(),
                          asset3D: _a3d.text.trim(),
                        ));
                        _nameCtrl.clear();
                        _a2d.clear();
                        _a3d.clear();
                      });
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer l\'animation'),
                  ),
                ],
              ),
            ),
          )),
        ),
      ],
    );
  }
}

// Template Tab pour créer un projet JSON
class TemplateTab extends StatelessWidget {
  const TemplateTab({super.key});
  @override
  Widget build(BuildContext context) {
    return _pad(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Créer un projet de démarrage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ce générateur crée un fichier JSON avec les modes, statistiques, héros, ennemis et projectiles définis.'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              final project = {
                'version': 1,
                'modeParDefaut': '2.5D',
                'modesSupportés': ['2D', '2.5D', '3D'],
                'stats': _defaultStatsList,
                'états': _defaultStates.keys.toList(),
                'projectiles': ['Arrow', 'Fireball', 'IceShard'],
                'héros': ['Alister','Hitomi','Steem','Yann','Lirine'],
                'ennemis': ['Slime','Goblin','Orc'],
              };
              final encoded = const JsonEncoder.withIndent('  ').convert(project);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('project.json (aperçu)'),
                  content: SizedBox(
                    width: 520,
                    child: SingleChildScrollView(child: Text(encoded)),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Générer project.json'),
          ),
        ],
      ),
    );
  }
}

// ==================== PETITES FONCTIONS UI ====================

Widget _pad(Widget child) => Padding(padding: const EdgeInsets.all(12), child: child);

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      color: const Color(0xFF165A9A),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class _Subheader extends StatelessWidget {
  const _Subheader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: const Color(0xFFE0ECFF),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _BlueHudBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  const _BlueHudBar({required this.title, this.actions});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2377D0), Color(0xFF1B5FA5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const a = Color(0xFF153B6F);
    const b = Color(0xFF0F2F59);
    const tile = 24.0;
    final paint = Paint();
    for (double y = 0; y < size.height; y += tile) {
      for (double x = 0; x < size.width; x += tile) {
        final isA = ((x / tile).floor() + (y / tile).floor()) % 2 == 0;
        paint.color = isA ? a : b;
        canvas.drawRect(Rect.fromLTWH(x, y, tile, tile), paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== CONSTANTES PAR DÉFAUT ====================

// Liste d'états par défaut à partir de « Système du jeu ».
final Map<String, StateDef> _defaultStates = {
  'Poison': StateDef('Poison', type: 'Malus', effect: 'Inflige des dégâts sur la durée.'),
  'Stun': StateDef('Stun', type: 'Malus', effect: 'Empêche de bouger ou d’agir.'),
  'Paralyze': StateDef('Paralyze', type: 'Malus', effect: 'Immobilise temporairement le personnage.'),
  'Blind': StateDef('Blind', type: 'Malus', effect: 'Réduit la précision des attaques.'),
  'Confuse': StateDef('Confuse', type: 'Malus', effect: 'Le personnage agit aléatoirement.'),
  'Slow': StateDef('Slow', type: 'Malus', effect: 'Réduit la vitesse de déplacement et d’attaque.'),
  'Injury': StateDef('Injury', type: 'Malus', effect: 'Baisse l’attaque physique.'),
  'Curse': StateDef('Curse', type: 'Malus', effect: 'Baisse la défense ou inflige divers effets.'),
  'Burn': StateDef('Burn', type: 'Malus', effect: 'Inflige des dégâts de feu sur la durée.'),
  'Freeze': StateDef('Freeze', type: 'Malus', effect: 'Immobilise et augmente les dégâts subis.'),
  'PowerUp': StateDef('PowerUp', type: 'Buff', effect: 'Augmente temporairement l’attaque.'),
  'DefenseUp': StateDef('DefenseUp', type: 'Buff', effect: 'Augmente temporairement la défense.'),
  'SpeedUp': StateDef('SpeedUp', type: 'Buff', effect: 'Augmente temporairement la vitesse.'),
};

// Liste de noms de stats par défaut pour le template.
final List<String> _defaultStatsList = [
  'HP','MP','HG','Atk','Def','MAtk','MDef','AtkSpeed','MoveSpeed','JumpHeight','CriticalHit','PoisonResist','MuteResist','StunResist','ParalyzeResist','BlindResist','ConfuseResist','SlowResist','InjuryResist','CurseResist','CosmosResist','ModifierResist','FireAffinity','WaterAffinity','WindAffinity','EarthAffinity','LightAffinity','DarkAffinity'
];

// Énumérations d'assets (valeurs symboliques)
enum AssetKind2D { sprite, tile, particles, projectile2D }
enum AssetKind3D { model, mesh, vfx, projectile3D }