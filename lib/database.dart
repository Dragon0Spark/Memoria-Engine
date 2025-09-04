import 'dart:convert';
import 'dart:io';

/// Data model for a hero in the database.
class HeroData {
  HeroData({required this.id, required this.name, this.classId = 0, this.level = 1});

  int id;
  String name;
  int classId;
  int level;

  factory HeroData.fromJson(Map<String, dynamic> json) => HeroData(
        id: json['id'] as int,
        name: json['name'] as String,
        classId: json['classId'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'classId': classId,
        'level': level,
      };
}

/// Data model for a class definition.
class ClassData {
  ClassData({required this.id, required this.name, Map<String, int>? baseStats})
      : baseStats = baseStats ?? <String, int>{};

  int id;
  String name;
  Map<String, int> baseStats;

  factory ClassData.fromJson(Map<String, dynamic> json) => ClassData(
        id: json['id'] as int,
        name: json['name'] as String,
        baseStats: (json['baseStats'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int)),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseStats': baseStats,
      };
}

/// Data model for an item definition.
class ItemData {
  ItemData({required this.id, required this.name, this.description = ''});

  int id;
  String name;
  String description;

  factory ItemData.fromJson(Map<String, dynamic> json) => ItemData(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

/// Data model for a skill definition.
class SkillData {
  SkillData({required this.id, required this.name, this.description = ''});

  int id;
  String name;
  String description;

  factory SkillData.fromJson(Map<String, dynamic> json) => SkillData(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

/// Data model for a weapon definition.
class WeaponData {
  WeaponData({required this.id, required this.name, this.description = ''});

  int id;
  String name;
  String description;

  factory WeaponData.fromJson(Map<String, dynamic> json) => WeaponData(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

/// Data model for an armor definition.
class ArmorData {
  ArmorData({required this.id, required this.name, this.description = ''});

  int id;
  String name;
  String description;

  factory ArmorData.fromJson(Map<String, dynamic> json) => ArmorData(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

/// Data model for an enemy definition.
class EnemyData {
  EnemyData({required this.id, required this.name, this.description = ''});

  int id;
  String name;
  String description;

  factory EnemyData.fromJson(Map<String, dynamic> json) => EnemyData(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

/// Data model for a troop (group of enemies).
class TroopData {
  TroopData({required this.id, required this.name, List<int>? members})
      : members = members ?? <int>[];

  int id;
  String name;
  List<int> members;

  factory TroopData.fromJson(Map<String, dynamic> json) => TroopData(
        id: json['id'] as int,
        name: json['name'] as String,
        members: (json['members'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': members,
      };
}

/// Data model for a state definition (status effects).
class StateData {
  StateData({required this.id, required this.name, this.description = ''});

  int id;
  String name;
  String description;

  factory StateData.fromJson(Map<String, dynamic> json) => StateData(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

/// Data model for an animation definition.
class AnimationData {
  AnimationData({required this.id, required this.name, this.description = ''});

  int id;
  String name;
  String description;

  factory AnimationData.fromJson(Map<String, dynamic> json) => AnimationData(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

/// Container for the whole database.
class GameDatabase {
  GameDatabase({
    List<HeroData>? heroes,
    List<ClassData>? classes,
    List<ItemData>? items,
    List<SkillData>? skills,
    List<WeaponData>? weapons,
    List<ArmorData>? armors,
    List<EnemyData>? enemies,
    List<TroopData>? troops,
    List<StateData>? states,
    List<AnimationData>? animations,
  })  : heroes = heroes ?? <HeroData>[],
        classes = classes ?? <ClassData>[],
        items = items ?? <ItemData>[],
        skills = skills ?? <SkillData>[],
        weapons = weapons ?? <WeaponData>[],
        armors = armors ?? <ArmorData>[],
        enemies = enemies ?? <EnemyData>[],
        troops = troops ?? <TroopData>[],
        states = states ?? <StateData>[],
        animations = animations ?? <AnimationData>[];

  final List<HeroData> heroes;
  final List<ClassData> classes;
  final List<ItemData> items;
  final List<SkillData> skills;
  final List<WeaponData> weapons;
  final List<ArmorData> armors;
  final List<EnemyData> enemies;
  final List<TroopData> troops;
  final List<StateData> states;
  final List<AnimationData> animations;

  /// Load database files from [directory].
  static Future<GameDatabase> load(Directory directory) async {
    Future<List<T>> loadList<T>(String name, T Function(Map<String, dynamic>) fromJson) async {
      final file = File('${directory.path}/$name.json');
      if (!await file.exists()) return <T>[];
      final data = jsonDecode(await file.readAsString()) as List<dynamic>;
      return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    final heroes = await loadList<HeroData>('heroes', HeroData.fromJson);
    final classes = await loadList<ClassData>('classes', ClassData.fromJson);
    final items = await loadList<ItemData>('items', ItemData.fromJson);
    final skills = await loadList<SkillData>('skills', SkillData.fromJson);
    final weapons = await loadList<WeaponData>('weapons', WeaponData.fromJson);
    final armors = await loadList<ArmorData>('armors', ArmorData.fromJson);
    final enemies = await loadList<EnemyData>('enemies', EnemyData.fromJson);
    final troops = await loadList<TroopData>('troops', TroopData.fromJson);
    final states = await loadList<StateData>('states', StateData.fromJson);
    final animations = await loadList<AnimationData>('animations', AnimationData.fromJson);
    return GameDatabase(
      heroes: heroes,
      classes: classes,
      items: items,
      skills: skills,
      weapons: weapons,
      armors: armors,
      enemies: enemies,
      troops: troops,
      states: states,
      animations: animations,
    );
  }

  /// Save database files to [directory].
  Future<void> save(Directory directory) async {
    Future<void> saveList<T>(String name, List<T> list, Map<String, dynamic> Function(T) toJson) async {
      final file = File('${directory.path}/$name.json');
      final data = jsonEncode(list.map(toJson).toList());
      await file.writeAsString(data);
    }

    await directory.create(recursive: true);
    await saveList<HeroData>('heroes', heroes, (e) => e.toJson());
    await saveList<ClassData>('classes', classes, (e) => e.toJson());
    await saveList<ItemData>('items', items, (e) => e.toJson());
    await saveList<SkillData>('skills', skills, (e) => e.toJson());
    await saveList<WeaponData>('weapons', weapons, (e) => e.toJson());
    await saveList<ArmorData>('armors', armors, (e) => e.toJson());
    await saveList<EnemyData>('enemies', enemies, (e) => e.toJson());
    await saveList<TroopData>('troops', troops, (e) => e.toJson());
    await saveList<StateData>('states', states, (e) => e.toJson());
    await saveList<AnimationData>('animations', animations, (e) => e.toJson());
  }
}

