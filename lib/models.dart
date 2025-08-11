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