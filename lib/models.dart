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
}

class TileLayer {
  TileLayer({required this.width, required this.height})
      : data = List.generate(height, (_) => List<int>.filled(width, -1));
  final int width;
  final int height;
  final List<List<int>> data;
}

class EventData {
  EventData({required this.name, required this.x, required this.y, this.pages = const []});
  String name;
  int x;
  int y;
  List<EventPage> pages;
}

class EventPage {
  EventPage({this.conditions = const {}, this.trigger = 'ActionButton', this.commands = const []});
  final Map<String, dynamic> conditions; // e.g., {'switch': 'A', 'value': true}
  String trigger; // ActionButton, PlayerTouch, Autorun, Parallel
  final List<EventCommand> commands;
}

class EventCommand {
  EventCommand(this.code, this.params);
  String code; // e.g., 'ShowText', 'ControlSwitch', 'TransferPlayer'
  final Map<String, dynamic> params;
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