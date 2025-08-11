import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

class SceneEditorPage extends StatefulWidget {
  const SceneEditorPage({
    super.key,
    required this.scene,
    required this.mapData,
    required this.cameraMode,
    this.pendingAssetName,
    this.onPendingAssetConsumed,
  });

  final SceneData scene;
  final MapData mapData;
  final CameraMode cameraMode;
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
    final Size canvasSize = _computeCanvasSize(map.width, map.height, widget.cameraMode);

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
                      cameraMode: widget.cameraMode,
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

  Size _computeCanvasSize(int w, int h, CameraMode mode) {
    if (mode == CameraMode.twoPointFiveD) {
      final double tileW = tileSize * 2;
      final double tileH = tileSize;
      final width = (w + h) * (tileW / 2) + tileW * 2;
      final height = (w + h) * (tileH / 2) + tileH * 3;
      return Size(width, height);
    }
    // 2D and 3D fallback to a planar canvas
    return Size(w * tileSize, h * tileSize);
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
    // For simplicity, use planar delta in grid space even in iso/3D modes
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
    if (widget.cameraMode == CameraMode.twoPointFiveD) {
      // Approximate inverse mapping by planar tiles for simplicity
      final gx = (p.dx / tileSize).floor().toDouble();
      final gy = (p.dy / tileSize).floor().toDouble();
      return Offset(gx, gy);
    }
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
    required this.cameraMode,
  });

  final int mapWidth;
  final int mapHeight;
  final double tileSize;
  final List<SceneObject> objects;
  final String? selectedObjectId;
  final CameraMode cameraMode;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintGrid(canvas, size);
    _paintObjects(canvas);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final bgA = Paint()..color = const Color(0xFF153B6F);
    final bgB = Paint()..color = const Color(0xFF0F2F59);
    for (double y = 0; y < size.height; y += tileSize) {
      for (double x = 0; x < size.width; x += tileSize) {
        final isA = ((x / tileSize).floor() + (y / tileSize).floor()) % 2 == 0;
        canvas.drawRect(Rect.fromLTWH(x, y, tileSize, tileSize), isA ? bgA : bgB);
      }
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    if (cameraMode == CameraMode.twoD) {
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
      return;
    }

    if (cameraMode == CameraMode.twoPointFiveD) {
      final double tileW = tileSize * 2;
      final double tileH = tileSize;
      final originX = (mapHeight * (tileW / 2)) + tileW;
      final originY = tileH;
      final stroke = Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (int y = 0; y < mapHeight; y++) {
        for (int x = 0; x < mapWidth; x++) {
          final center = _isoProject(x, y, tileW, tileH, originX, originY);
          final path = Path();
          path.moveTo(center.dx, center.dy - tileH / 2);
          path.lineTo(center.dx + tileW / 2, center.dy);
          path.lineTo(center.dx, center.dy + tileH / 2);
          path.lineTo(center.dx - tileW / 2, center.dy);
          path.close();
          canvas.drawPath(path, stroke);
        }
      }
      return;
    }

    // Pseudo-3D: draw a faint perspective-like grid using iso projection as a stand-in
    final double tileW = tileSize * 2.4;
    final double tileH = tileSize * 1.2;
    final originX = (mapHeight * (tileW / 2)) + tileW;
    final originY = tileH * 1.5;
    final stroke = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        final center = _isoProject(x, y, tileW, tileH, originX, originY);
        final rect = Rect.fromCenter(center: center, width: tileW, height: tileH);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), stroke);
      }
    }
  }

  void _paintObjects(Canvas canvas) {
    if (cameraMode == CameraMode.twoD) {
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
      return;
    }

    final drawList = List<SceneObject>.from(objects)
      ..sort((a, b) => (a.y != b.y) ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

    if (cameraMode == CameraMode.twoPointFiveD) {
      final double tileW = tileSize * 2;
      final double tileH = tileSize;
      final originX = (mapHeight * (tileW / 2)) + tileW;
      final originY = tileH;
      for (final o in drawList) {
        final c = _isoProject(o.x, o.y, tileW, tileH, originX, originY);
        final path = Path();
        path.moveTo(c.dx, c.dy - tileH / 2);
        path.lineTo(c.dx + tileW / 2, c.dy);
        path.lineTo(c.dx, c.dy + tileH / 2);
        path.lineTo(c.dx - tileW / 2, c.dy);
        path.close();
        canvas.drawPath(path, Paint()..color = _colorFor(o).withOpacity(0.9));
        if (o.id == selectedObjectId) {
          canvas.drawPath(path, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.yellowAccent);
        }
      }
      return;
    }

    // Pseudo-3D: draw a small vertical extrusion
    final double tileW = tileSize * 2.4;
    final double tileH = tileSize * 1.2;
    final originX = (mapHeight * (tileW / 2)) + tileW;
    final originY = tileH * 1.5;
    for (final o in drawList) {
      final base = _isoProject(o.x, o.y, tileW, tileH, originX, originY);
      final top = base.translate(0, -tileSize * 0.8);
      final paint = Paint()..color = _colorFor(o).withOpacity(0.95);
      // draw column
      canvas.drawLine(base, top, Paint()
        ..color = paint.color
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round);
      // highlight selection
      if (o.id == selectedObjectId) {
        canvas.drawCircle(top, 6, Paint()..color = Colors.yellowAccent);
      }
    }
  }

  Offset _isoProject(int x, int y, double tileW, double tileH, double originX, double originY) {
    final screenX = (x - y) * (tileW / 2) + originX;
    final screenY = (x + y) * (tileH / 2) + originY;
    return Offset(screenX, screenY);
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
        oldDelegate.cameraMode != cameraMode;
  }
}