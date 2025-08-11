import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'event_editor.dart';
import 'models.dart';

enum MapTool { pencil, rectangle, fill, eraser, event }

class MapEditorPage extends StatefulWidget {
  const MapEditorPage({super.key, required this.mapData});
  final MapData mapData;
  @override
  State<MapEditorPage> createState() => _MapEditorPageState();
}

class _MapEditorPageState extends State<MapEditorPage> {
  static const double tileSize = 24.0;
  MapTool currentTool = MapTool.pencil;
  MapLayerKind currentLayer = MapLayerKind.layerA;
  bool showGrid = true;
  bool showLayersA = true;
  bool showLayersB = true;
  bool showLayersC = true;
  bool showLayersD = true;
  bool showEvents = true;

  // Palette de "tiles" simplifiée: id -> couleur
  final Map<int, Color> palette = {
    // 0-5: tons verts
    0: const Color(0xFFa8d08d),
    1: const Color(0xFF92c47d),
    2: const Color(0xFF70ad47),
    3: const Color(0xFF385723),
    4: const Color(0xFF6aa84f),
    5: const Color(0xFF93c47d),
    // 6-10: tons bruns
    6: const Color(0xFFb45f06),
    7: const Color(0xFF783f04),
    8: const Color(0xFFa0612b),
    9: const Color(0xFF7f4c2a),
    10: const Color(0xFFc27c2c),
    // 11-15: tons gris
    11: const Color(0xFF999999),
    12: const Color(0xFFb7b7b7),
    13: const Color(0xFF7f7f7f),
    14: const Color(0xFF5b5b5b),
    15: const Color(0xFFd9d9d9),
  };

  int selectedTileId = 0;

  // Rectangle tool temp selection
  Offset? dragStart;
  Offset? dragCurrent;

  @override
  Widget build(BuildContext context) {
    final map = widget.mapData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(map),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasWidth = map.width * tileSize;
                    final canvasHeight = map.height * tileSize;
                    return Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Listener(
                            onPointerDown: (e) => _onPointer(e.localPosition),
                            onPointerMove: (e) => _onPointer(e.localPosition),
                            onPointerUp: (_) => setState(() {
                              if (currentTool == MapTool.rectangle) {
                                _applyRectangle();
                              }
                              dragStart = null;
                              dragCurrent = null;
                            }),
                            child: CustomPaint(
                              size: Size(canvasWidth, canvasHeight),
                              painter: _MapPainter(
                                map: map,
                                palette: palette,
                                tileSize: tileSize,
                                showGrid: showGrid,
                                showLayers: {
                                  MapLayerKind.layerA: showLayersA,
                                  MapLayerKind.layerB: showLayersB,
                                  MapLayerKind.layerC: showLayersC,
                                  MapLayerKind.layerD: showLayersD,
                                  MapLayerKind.events: showEvents,
                                },
                                draggingRect: _currentDragRect(),
                                isRectangleTool: currentTool == MapTool.rectangle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildPalette(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(MapData map) {
    return Container(
      height: 44,
      color: const Color(0xFF165A9A),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: Colors.white),
          const SizedBox(width: 8),
          Text('${map.name} — ${map.width}x${map.height}', style: const TextStyle(color: Colors.white)),
          const VerticalDivider(color: Colors.white38),
          _toolButton(Icons.edit, MapTool.pencil),
          _toolButton(Icons.crop_square, MapTool.rectangle),
          _toolButton(Icons.format_color_fill, MapTool.fill),
          _toolButton(Icons.layers_clear, MapTool.eraser),
          _toolButton(Icons.flag, MapTool.event),
          const SizedBox(width: 8),
          _layerDropdown(),
          const SizedBox(width: 8),
          _toggle('Grille', showGrid, (v) => setState(() => showGrid = v)),
          const VerticalDivider(color: Colors.white38),
          _toggle('A', showLayersA, (v) => setState(() => showLayersA = v)),
          _toggle('B', showLayersB, (v) => setState(() => showLayersB = v)),
          _toggle('C', showLayersC, (v) => setState(() => showLayersC = v)),
          _toggle('D', showLayersD, (v) => setState(() => showLayersD = v)),
          _toggle('Evts', showEvents, (v) => setState(() => showEvents = v)),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              setState(() {
                for (final layer in map.layers.values) {
                  for (var y = 0; y < layer.height; y++) {
                    for (var x = 0; x < layer.width; x++) {
                      layer.data[y][x] = -1;
                    }
                  }
                }
                map.events.clear();
              });
            },
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            label: const Text('Effacer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, MapTool tool) {
    final selected = currentTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => setState(() => currentTool = tool),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _layerDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<MapLayerKind>(
        value: currentLayer,
        underline: const SizedBox.shrink(),
        dropdownColor: const Color(0xFF165A9A),
        iconEnabledColor: Colors.white,
        style: const TextStyle(color: Colors.white),
        items: const [
          DropdownMenuItem(value: MapLayerKind.layerA, child: Text('Calque A')),
          DropdownMenuItem(value: MapLayerKind.layerB, child: Text('Calque B')),
          DropdownMenuItem(value: MapLayerKind.layerC, child: Text('Calque C')),
          DropdownMenuItem(value: MapLayerKind.layerD, child: Text('Calque D')),
          DropdownMenuItem(value: MapLayerKind.events, child: Text('Evénements')),
        ],
        onChanged: (v) => setState(() => currentLayer = v ?? MapLayerKind.layerA),
      ),
    );
  }

  Widget _buildPalette() {
    final entries = palette.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return SizedBox(
      width: 180,
      child: Column(
        children: [
          Container(
            height: 34,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFF165A9A),
            child: const Text('Palette', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              children: [
                for (final e in entries)
                  InkWell(
                    onTap: () => setState(() => selectedTileId = e.key),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: e.value,
                        border: Border.all(
                          color: selectedTileId == e.key ? Colors.black : Colors.black26,
                          width: selectedTileId == e.key ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text('${e.key}', style: const TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onPointer(Offset pos) {
    final map = widget.mapData;
    final x = (pos.dx / tileSize).floor();
    final y = (pos.dy / tileSize).floor();
    if (x < 0 || y < 0 || x >= map.width || y >= map.height) return;

    if (currentTool == MapTool.event || currentLayer == MapLayerKind.events) {
      // Placement ou sélection d'événement
      setState(() {
        final existing = map.events.where((e) => e.x == x && e.y == y).toList();
        if (existing.isEmpty) {
          final evt = EventData(name: 'Evt${map.events.length + 1}', x: x, y: y, pages: [EventPage(commands: const [])]);
          map.events.add(evt);
          showDialog(context: context, builder: (_) => EventEditorDialog(event: evt));
        } else {
          showDialog(context: context, builder: (_) => EventEditorDialog(event: existing.first));
        }
      });
      return;
    }

    switch (currentTool) {
      case MapTool.pencil:
        setState(() {
          final layer = map.layers[currentLayer]!;
          layer.data[y][x] = selectedTileId;
        });
        break;
      case MapTool.eraser:
        setState(() {
          final layer = map.layers[currentLayer]!;
          layer.data[y][x] = -1;
        });
        break;
      case MapTool.fill:
        setState(() => _floodFill(x, y));
        break;
      case MapTool.rectangle:
        setState(() {
          dragCurrent = Offset(x.toDouble(), y.toDouble());
          dragStart ??= dragCurrent;
        });
        break;
      case MapTool.event:
        // handled above
        break;
    }
  }

  void _applyRectangle() {
    final map = widget.mapData;
    if (dragStart == null || dragCurrent == null || currentLayer == MapLayerKind.events) return;
    final x0 = dragStart!.dx.toInt();
    final y0 = dragStart!.dy.toInt();
    final x1 = dragCurrent!.dx.toInt();
    final y1 = dragCurrent!.dy.toInt();
    final minX = math.min(x0, x1);
    final maxX = math.max(x0, x1);
    final minY = math.min(y0, y1);
    final maxY = math.max(y0, y1);
    final layer = map.layers[currentLayer]!;
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        layer.data[y][x] = selectedTileId;
      }
    }
  }

  void _floodFill(int sx, int sy) {
    final map = widget.mapData;
    if (currentLayer == MapLayerKind.events) return;
    final layer = map.layers[currentLayer]!;
    final target = layer.data[sy][sx];
    if (target == selectedTileId) return;

    final w = layer.width;
    final h = layer.height;
    final List<Offset> stack = [Offset(sx.toDouble(), sy.toDouble())];
    while (stack.isNotEmpty) {
      final o = stack.removeLast();
      final x = o.dx.toInt();
      final y = o.dy.toInt();
      if (x < 0 || y < 0 || x >= w || y >= h) continue;
      if (layer.data[y][x] != target) continue;
      layer.data[y][x] = selectedTileId;
      stack.addAll([
        Offset(x - 1, y),
        Offset(x + 1, y),
        Offset(x, y - 1),
        Offset(x, y + 1),
      ]);
    }
  }

  Rect? _currentDragRect() {
    if (dragStart == null || dragCurrent == null) return null;
    final x0 = dragStart!.dx;
    final y0 = dragStart!.dy;
    final x1 = dragCurrent!.dx;
    final y1 = dragCurrent!.dy;
    final left = math.min(x0, x1) * tileSize;
    final top = math.min(y0, y1) * tileSize;
    final right = (math.max(x0, x1) + 1) * tileSize;
    final bottom = (math.max(y0, y1) + 1) * tileSize;
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.map,
    required this.palette,
    required this.tileSize,
    required this.showGrid,
    required this.showLayers,
    required this.draggingRect,
    required this.isRectangleTool,
  });

  final MapData map;
  final Map<int, Color> palette;
  final double tileSize;
  final bool showGrid;
  final Map<MapLayerKind, bool> showLayers;
  final Rect? draggingRect;
  final bool isRectangleTool;

  @override
  void paint(Canvas canvas, Size size) {
    final bgA = Paint()..color = const Color(0xFF153B6F);
    final bgB = Paint()..color = const Color(0xFF0F2F59);

    // Fond damier
    for (double y = 0; y < size.height; y += tileSize) {
      for (double x = 0; x < size.width; x += tileSize) {
        final isA = ((x / tileSize).floor() + (y / tileSize).floor()) % 2 == 0;
        canvas.drawRect(Rect.fromLTWH(x, y, tileSize, tileSize), isA ? bgA : bgB);
      }
    }

    void paintLayer(TileLayer layer) {
      for (int y = 0; y < layer.height; y++) {
        for (int x = 0; x < layer.width; x++) {
          final t = layer.data[y][x];
          if (t < 0) continue;
          final c = palette[t] ?? Colors.white;
          final r = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = c);
        }
      }
    }

    if (showLayers[MapLayerKind.layerA] ?? true) paintLayer(map.layers[MapLayerKind.layerA]!);
    if (showLayers[MapLayerKind.layerB] ?? true) paintLayer(map.layers[MapLayerKind.layerB]!);
    if (showLayers[MapLayerKind.layerC] ?? true) paintLayer(map.layers[MapLayerKind.layerC]!);
    if (showLayers[MapLayerKind.layerD] ?? true) paintLayer(map.layers[MapLayerKind.layerD]!);

    // Evénements
    if (showLayers[MapLayerKind.events] ?? true) {
      for (final e in map.events) {
        final cx = e.x * tileSize + tileSize / 2;
        final cy = e.y * tileSize + tileSize / 2;
        final r = Rect.fromCenter(center: Offset(cx, cy), width: tileSize * 0.8, height: tileSize * 0.8);
        final rp = RRect.fromRectAndRadius(r, const Radius.circular(4));
        canvas.drawRRect(rp, Paint()..color = const Color(0xFFffc107));
        final tp = TextPainter(
          text: TextSpan(text: e.name, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: tileSize * 1.2);
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      }
    }

    // Grille
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white10
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (double x = 0; x <= size.width; x += tileSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y <= size.height; y += tileSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // Rectangle en cours
    if (isRectangleTool && draggingRect != null) {
      final r = draggingRect!;
      canvas.drawRect(r, Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.fill);
      canvas.drawRect(r, Paint()
        ..color = Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.palette != palette ||
        oldDelegate.tileSize != tileSize ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showLayers != showLayers ||
        oldDelegate.draggingRect != draggingRect ||
        oldDelegate.isRectangleTool != isRectangleTool;
  }
}