import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

class SceneEditorPage extends StatefulWidget {
  const SceneEditorPage({
    super.key,
    required this.scene,
    required this.mapData,
    required this.is3D,
    this.pendingAssetName,
    this.onPendingAssetConsumed,
  });

  final SceneData scene;
  final MapData mapData;
  final bool is3D;
  final String? pendingAssetName;
  final VoidCallback? onPendingAssetConsumed;

  @override
  State<SceneEditorPage> createState() => _SceneEditorPageState();
}

class _SceneEditorPageState extends State<SceneEditorPage> {
  static const double tileSize = 24.0;

  String? selectedObjectId;
  Offset? dragStartWorld;
  int? dragStartObjX;
  int? dragStartObjY;

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final map = widget.mapData;
    final Size canvasSize = Size(map.width * tileSize, map.height * tileSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(),
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _onTap(details.localPosition),
                  onPanStart: (details) => _onPanStart(details.localPosition),
                  onPanUpdate: (details) => _onPanUpdate(details.localPosition),
                  onPanEnd: (_) => _onPanEnd(),
                  child: CustomPaint(
                    size: canvasSize,
                    painter: _ScenePainter(
                      mapWidth: map.width,
                      mapHeight: map.height,
                      tileSize: tileSize,
                      objects: scene.objects,
                      selectedObjectId: selectedObjectId,
                      is3D: widget.is3D,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final pending = widget.pendingAssetName;
    return Container(
      height: 44,
      color: const Color(0xFF165A9A),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Icon(Icons.view_in_ar, color: Colors.white),
          const SizedBox(width: 8),
          Text('Scène — ${widget.scene.name}', style: const TextStyle(color: Colors.white)),
          const Spacer(),
          if (pending != null)
            Row(
              children: [
                const Icon(Icons.add_location_alt_outlined, color: Colors.white),
                const SizedBox(width: 6),
                Text('Cliquez pour placer: $pending', style: const TextStyle(color: Colors.white)),
              ],
            ),
        ],
      ),
    );
  }

  void _onTap(Offset localPos) {
    final grid = _pixelToGrid(localPos);

    if (widget.pendingAssetName != null) {
      final newObj = _createObjectFromAsset(widget.pendingAssetName!, grid.dx.toInt(), grid.dy.toInt());
      setState(() {
        widget.scene.objects.add(newObj);
        selectedObjectId = newObj.id;
      });
      widget.onPendingAssetConsumed?.call();
      return;
    }

    // Select object if any at position
    final hit = _findTopmostObjectAt(grid.dx.toInt(), grid.dy.toInt());
    setState(() {
      selectedObjectId = hit?.id;
    });
  }

  void _onPanStart(Offset localPos) {
    final grid = _pixelToGrid(localPos);
    final hit = _findTopmostObjectAt(grid.dx.toInt(), grid.dy.toInt());
    if (hit == null) return;
    setState(() {
      selectedObjectId = hit.id;
      dragStartWorld = localPos;
      dragStartObjX = hit.x;
      dragStartObjY = hit.y;
    });
  }

  void _onPanUpdate(Offset localPos) {
    if (selectedObjectId == null || dragStartWorld == null) return;
    final dx = (localPos.dx - dragStartWorld!.dx) / tileSize;
    final dy = (localPos.dy - dragStartWorld!.dy) / tileSize;
    final obj = widget.scene.objects.firstWhere((o) => o.id == selectedObjectId);
    setState(() {
      obj.x = (dragStartObjX! + dx.round()).clamp(0, widget.mapData.width - 1);
      obj.y = (dragStartObjY! + dy.round()).clamp(0, widget.mapData.height - 1);
    });
  }

  void _onPanEnd() {
    dragStartWorld = null;
    dragStartObjX = null;
    dragStartObjY = null;
  }

  Offset _pixelToGrid(Offset p) {
    final gx = (p.dx / tileSize).floor().toDouble();
    final gy = (p.dy / tileSize).floor().toDouble();
    return Offset(gx, gy);
  }

  SceneObject? _findTopmostObjectAt(int x, int y) {
    for (int i = widget.scene.objects.length - 1; i >= 0; i--) {
      final o = widget.scene.objects[i];
      if (o.x == x && o.y == y) return o;
    }
    return null;
  }

  SceneObject _createObjectFromAsset(String assetName, int x, int y) {
    final kind = _inferKindFromAsset(assetName);
    return SceneObject(
      id: '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}',
      name: assetName,
      kind: kind,
      x: x,
      y: y,
      asset: assetName,
    );
  }

  SceneObjectKind _inferKindFromAsset(String assetName) {
    final lower = assetName.toLowerCase();
    if (lower.endsWith('.glb') || lower.endsWith('.fbx') || lower.endsWith('.obj')) {
      return SceneObjectKind.model3D;
    }
    return SceneObjectKind.sprite2D;
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.mapWidth,
    required this.mapHeight,
    required this.tileSize,
    required this.objects,
    required this.selectedObjectId,
    required this.is3D,
  });

  final int mapWidth;
  final int mapHeight;
  final double tileSize;
  final List<SceneObject> objects;
  final String? selectedObjectId;
  final bool is3D;

  @override
  void paint(Canvas canvas, Size size) {
    // Checker background
    final bgA = Paint()..color = const Color(0xFF153B6F);
    final bgB = Paint()..color = const Color(0xFF0F2F59);
    for (double y = 0; y < size.height; y += tileSize) {
      for (double x = 0; x < size.width; x += tileSize) {
        final isA = ((x / tileSize).floor() + (y / tileSize).floor()) % 2 == 0;
        canvas.drawRect(Rect.fromLTWH(x, y, tileSize, tileSize), isA ? bgA : bgB);
      }
    }

    // Grid
    final gridPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int x = 0; x <= mapWidth; x++) {
      final dx = x * tileSize;
      canvas.drawLine(Offset(dx, 0), Offset(dx, mapHeight * tileSize), gridPaint);
    }
    for (int y = 0; y <= mapHeight; y++) {
      final dy = y * tileSize;
      canvas.drawLine(Offset(0, dy), Offset(mapWidth * tileSize, dy), gridPaint);
    }

    // Draw objects
    for (final o in objects) {
      final rect = Rect.fromLTWH(o.x * tileSize, o.y * tileSize, tileSize, tileSize);
      final color = _colorFor(o);
      final rrect = RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(4));
      canvas.drawRRect(rrect, Paint()..color = color);
      if (o.id == selectedObjectId) {
        canvas.drawRRect(rrect, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.yellowAccent);
      }
    }
  }

  Color _colorFor(SceneObject o) {
    switch (o.kind) {
      case SceneObjectKind.model3D:
        return const Color(0xFF8BC34A);
      case SceneObjectKind.light:
        return const Color(0xFFFFF176);
      case SceneObjectKind.camera:
        return const Color(0xFF80DEEA);
      case SceneObjectKind.sound:
        return const Color(0xFFFFB74D);
      case SceneObjectKind.sprite2D:
      default:
        return const Color(0xFF64B5F6);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) {
    return oldDelegate.objects != objects ||
        oldDelegate.selectedObjectId != selectedObjectId ||
        oldDelegate.mapWidth != mapWidth ||
        oldDelegate.mapHeight != mapHeight ||
        oldDelegate.is3D != is3D;
  }
}