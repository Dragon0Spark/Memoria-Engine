enum CameraMode { twoD, twoPointFiveD, threeD }

enum MapLayerKind { layerA, layerB, layerC, layerD, events }

class MapData {
  MapData({
    required this.name,
    required this.width,
    required this.height,
    this.tilesetName = 'Default',
  }) {
    layers = {
      MapLayerKind.layerA: TileLayer(width: width, height: height),
      MapLayerKind.layerB: TileLayer(width: width, height: height),
      MapLayerKind.layerC: TileLayer(width: width, height: height),
      MapLayerKind.layerD: TileLayer(width: width, height: height),
    };
    events = <EventData>[];
  }

  final String name;
  int width;
  int height;
  String tilesetName;
  late Map<MapLayerKind, TileLayer> layers;
  late List<EventData> events;

  factory MapData.fromJson(Map<String, dynamic> json) {
    final map = MapData(
      name: json['name'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      tilesetName: json['tilesetName'] as String? ?? 'Default',
    );
    final layersJson = json['layers'] as Map<String, dynamic>? ?? {};
    layersJson.forEach((key, value) {
      final kind = MapLayerKind.values.firstWhere(
        (e) => e.name == key,
        orElse: () => MapLayerKind.layerA,
      );
      map.layers[kind] = TileLayer.fromJson(value as Map<String, dynamic>);
    });
    final eventsJson = json['events'] as List<dynamic>? ?? [];
    map.events =
        eventsJson.map((e) => EventData.fromJson(e as Map<String, dynamic>)).toList();
    return map;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'width': width,
        'height': height,
        'tilesetName': tilesetName,
        'layers': {for (final e in layers.entries) e.key.name: e.value.toJson()},
        'events': events.map((e) => e.toJson()).toList(),
      };
}

class TileLayer {
  TileLayer({required this.width, required this.height})
      : data = List.generate(height, (_) => List<int>.filled(width, -1));
  final int width;
  final int height;
  final List<List<int>> data;

  factory TileLayer.fromJson(Map<String, dynamic> json) {
    final width = json['width'] as int;
    final height = json['height'] as int;
    final layer = TileLayer(width: width, height: height);
    final rows = json['data'] as List<dynamic>? ?? [];
    for (var y = 0; y < height && y < rows.length; y++) {
      final row = rows[y] as List<dynamic>;
      for (var x = 0; x < width && x < row.length; x++) {
        layer.data[y][x] = row[x] as int;
      }
    }
    return layer;
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'data': data,
      };
}

class EventData {
  EventData({required this.name, required this.x, required this.y, this.pages = const []});
  String name;
  int x;
  int y;
  List<EventPage> pages;

  factory EventData.fromJson(Map<String, dynamic> json) => EventData(
        name: json['name'] as String,
        x: json['x'] as int,
        y: json['y'] as int,
        pages: (json['pages'] as List<dynamic>? ?? [])
            .map((e) => EventPage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'x': x,
        'y': y,
        'pages': pages.map((p) => p.toJson()).toList(),
      };
}

class EventPage {
  EventPage({this.conditions = const {}, this.trigger = 'ActionButton', this.commands = const []});
  final Map<String, dynamic> conditions; // e.g., {'switch': 'A', 'value': true}
  String trigger; // ActionButton, PlayerTouch, Autorun, Parallel
  final List<EventCommand> commands;

  factory EventPage.fromJson(Map<String, dynamic> json) => EventPage(
        conditions: (json['conditions'] as Map<String, dynamic>? ?? {}),
        trigger: json['trigger'] as String? ?? 'ActionButton',
        commands: (json['commands'] as List<dynamic>? ?? [])
            .map((e) => EventCommand.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'conditions': conditions,
        'trigger': trigger,
        'commands': commands.map((c) => c.toJson()).toList(),
      };
}

class EventCommand {
  EventCommand(this.code, this.params);
  String code; // e.g., 'ShowText', 'ControlSwitch', 'TransferPlayer'
  final Map<String, dynamic> params;

  factory EventCommand.fromJson(Map<String, dynamic> json) =>
      EventCommand(json['code'] as String, json['params'] as Map<String, dynamic>? ?? {});

  Map<String, dynamic> toJson() => {
        'code': code,
        'params': params,
      };
}

// Scene editor models

enum SceneObjectKind { sprite2D, model3D, light, camera, sound }

class SceneObject {
  SceneObject({
    required this.id,
    required this.name,
    required this.kind,
    required this.x,
    required this.y,
    this.asset = '',
    Map<String, dynamic>? props,
  }) : props = props ?? <String, dynamic>{};

  String id;
  String name;
  SceneObjectKind kind;
  int x;
  int y;
  String asset;
  final Map<String, dynamic> props;
}

class SceneData {
  SceneData({required this.name, List<SceneObject>? objects})
      : objects = objects ?? <SceneObject>[];

  String name;
  final List<SceneObject> objects;

  SceneObject? findObjectAt(int x, int y) {
    for (final obj in objects) {
      if (obj.x == x && obj.y == y) return obj;
    }
    return null;
  }
}