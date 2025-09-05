import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // 3D camera parameters
  double camX = 0;
  double camY = 10;
  double camZ = 20;
  double camYaw = math.pi;
  double camPitch = -math.pi / 6;
  final FocusNode _focusNode = FocusNode();
  Size? _lastCanvasSize;

  @override
  void initState() {
    super.initState();
    if (widget.cameraMode == CameraMode.threeD) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant SceneEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cameraMode == CameraMode.threeD && !_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final map = widget.mapData;
    final Size canvasSize =
        _computeCanvasSize(map.width, map.height, widget.cameraMode);
    _lastCanvasSize = canvasSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(),
        Expanded(child: _buildViewport(scene, map, canvasSize)),
      ],
    );
  }

  Widget _buildViewport(SceneData scene, MapData map, Size canvasSize) {
    if (widget.cameraMode == CameraMode.threeD) {
      return Focus(
        focusNode: _focusNode,
        onKey: _handleKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _onTap(details.localPosition),
          onPanUpdate: (details) => _onPanRotate3D(details.delta),
          child: CustomPaint(
            size: canvasSize,
            painter: _ScenePainter(
              mapWidth: map.width,
              mapHeight: map.height,
              tileSize: tileSize,
              objects: scene.objects,
              selectedObjectId: selectedObjectId,
              cameraMode: widget.cameraMode,
              camX: camX,
              camY: camY,
              camZ: camZ,
              camYaw: camYaw,
              camPitch: camPitch,
            ),
          ),
        ),
      );
    }

    return Scrollbar(
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
    );
  }

  KeyEventResult _handleKey(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
    const double step = 1.0;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyW:
        camX += math.sin(camYaw) * step;
        camZ -= math.cos(camYaw) * step;
        break;
      case LogicalKeyboardKey.keyS:
        camX -= math.sin(camYaw) * step;
        camZ += math.cos(camYaw) * step;
        break;
      case LogicalKeyboardKey.keyA:
        camX -= math.cos(camYaw) * step;
        camZ -= math.sin(camYaw) * step;
        break;
      case LogicalKeyboardKey.keyD:
        camX += math.cos(camYaw) * step;
        camZ += math.sin(camYaw) * step;
        break;
      case LogicalKeyboardKey.space:
        camY += step;
        break;
      case LogicalKeyboardKey.shiftLeft:
        camY -= step;
        break;
      case LogicalKeyboardKey.arrowLeft:
        camYaw -= 0.1;
        break;
      case LogicalKeyboardKey.arrowRight:
        camYaw += 0.1;
        break;
      case LogicalKeyboardKey.arrowUp:
        camPitch += 0.1;
        break;
      case LogicalKeyboardKey.arrowDown:
        camPitch -= 0.1;
        break;
      default:
        return KeyEventResult.ignored;
    }
    setState(() {});
    return KeyEventResult.handled;
  }

  void _onPanRotate3D(Offset delta) {
    setState(() {
      camYaw += delta.dx * 0.01;
      camPitch =
          (camPitch + delta.dy * 0.01).clamp(-math.pi / 2 + 0.01, math.pi / 2 - 0.01);
    });
  }

  Size _computeCanvasSize(int w, int h, CameraMode mode) {
    if (mode == CameraMode.twoPointFiveD) {
      final double tileW = tileSize * 2;
      final double tileH = tileSize;
      final width = (w + h) * (tileW / 2) + tileW * 2;
      final height = (w + h) * (tileH / 2) + tileH * 3;
      return Size(width, height);
    }
    if (mode == CameraMode.threeD) {
      return const Size(800, 600);
    }
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
      final SceneObject newObj;
      if (widget.cameraMode == CameraMode.threeD) {
        newObj = _createObjectFromAsset(
            widget.pendingAssetName!, grid.dx.toInt(), grid.dy.toInt(), 0);
      } else {
        newObj = _createObjectFromAsset(
            widget.pendingAssetName!, grid.dx.toInt(), grid.dy.toInt());
      }
      if (!_canPlaceObject(newObj.kind, widget.cameraMode)) {
        return;
      }
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
    if (widget.cameraMode == CameraMode.threeD && _lastCanvasSize != null) {
      final width = _lastCanvasSize!.width;
      final height = _lastCanvasSize!.height;
      const double fov = 200.0;
      final double x = p.dx - width / 2;
      final double y = p.dy - height / 2;
      final double nx = x / fov;
      final double ny = y / fov;
      double rx = nx;
      double ry = ny;
      double rz = 1.0;
      final cy = math.cos(camYaw);
      final sy = math.sin(camYaw);
      final cp = math.cos(camPitch);
      final sp = math.sin(camPitch);
      final ryp = ry * cp + rz * sp;
      final rzp = -ry * sp + rz * cp;
      final rxx = rx * cy + rzp * sy;
      final rzz = -rx * sy + rzp * cy;
      final ryy = ryp;
      final t = -camY / ryy;
      final gx = camX + rxx * t;
      final gz = camZ + rzz * t;
      return Offset(gx, gz);
    }
    final gx = (p.dx / tileSize).floor().toDouble();
    final gy = (p.dy / tileSize).floor().toDouble();
    return Offset(gx, gy);
  }

  bool _canPlaceObject(SceneObjectKind kind, CameraMode mode) {
    switch (mode) {
      case CameraMode.twoD:
        return kind == SceneObjectKind.model3D;
      case CameraMode.twoPointFiveD:
        return kind == SceneObjectKind.sprite2D ||
            kind == SceneObjectKind.model3D;
      case CameraMode.threeD:
        return true;
    }
  }

  SceneObject? _findTopmostObjectAt(int x, int y) {
    for (int i = widget.scene.objects.length - 1; i >= 0; i--) {
      final o = widget.scene.objects[i];
      if (o.x == x && o.y == y) return o;
    }
    return null;
  }

  SceneObject _createObjectFromAsset(String assetName, int x, int y,
      [int z = 0]) {
    final kind = _inferKindFromAsset(assetName);
    return SceneObject(
      id: '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}',
      name: assetName,
      kind: kind,
      x: x,
      y: y,
      z: z,
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
    this.camX = 0,
    this.camY = 10,
    this.camZ = 10,
    this.camYaw = 0,
    this.camPitch = 0,
  });

  final int mapWidth;
  final int mapHeight;
  final double tileSize;
  final List<SceneObject> objects;
  final String? selectedObjectId;
  final CameraMode cameraMode;
  final double camX;
  final double camY;
  final double camZ;
  final double camYaw;
  final double camPitch;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    if (cameraMode == CameraMode.threeD) {
      _paintGrid3D(canvas, size);
      _paintObjects3D(canvas, size);
    } else {
      _paintGrid(canvas, size);
      _paintObjects(canvas);
    }
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

    // no grid for other modes here
  }

  void _paintObjects(Canvas canvas) {
    if (cameraMode == CameraMode.twoD) {
      for (final o in objects) {
        final rect = Rect.fromLTWH(
            o.x * tileSize, o.y * tileSize, tileSize, tileSize);
        final color = _colorFor(o);
        final rrect =
            RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(4));
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
  }

  void _paintGrid3D(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke;
    for (int x = 0; x <= mapWidth; x++) {
      final p1 = _project3D(x.toDouble(), 0, 0, size);
      final p2 = _project3D(x.toDouble(), 0, mapHeight.toDouble(), size);
      canvas.drawLine(p1, p2, paint);
    }
    for (int z = 0; z <= mapHeight; z++) {
      final p1 = _project3D(0, 0, z.toDouble(), size);
      final p2 = _project3D(mapWidth.toDouble(), 0, z.toDouble(), size);
      canvas.drawLine(p1, p2, paint);
    }
  }

  void _paintObjects3D(Canvas canvas, Size size) {
    for (final o in objects) {
      final pos = _project3D(
          o.x.toDouble(), o.z.toDouble(), o.y.toDouble(), size);
      final paint = Paint()..color = _colorFor(o).withOpacity(0.95);
      canvas.drawCircle(pos, 6, paint);
      if (o.id == selectedObjectId) {
        canvas.drawCircle(pos, 8, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.yellowAccent);
      }
    }
  }

  Offset _project3D(
      double wx, double wy, double wz, Size size) {
    final dx = wx - camX;
    final dy = wy - camY;
    final dz = wz - camZ;
    final cy = math.cos(camYaw);
    final sy = math.sin(camYaw);
    final cp = math.cos(camPitch);
    final sp = math.sin(camPitch);
    final xz = dx * cy - dz * sy;
    final zz = dx * sy + dz * cy;
    final yz = dy * cp - zz * sp;
    final zz2 = dy * sp + zz * cp;
    const double fov = 200.0;
    final scale = fov / (fov + zz2);
    final sx = xz * scale * tileSize + size.width / 2;
    final sy = yz * scale * tileSize + size.height / 2;
    return Offset(sx, sy);
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
        oldDelegate.cameraMode != cameraMode ||
        oldDelegate.camX != camX ||
        oldDelegate.camY != camY ||
        oldDelegate.camZ != camZ ||
        oldDelegate.camYaw != camYaw ||
        oldDelegate.camPitch != camPitch;
  }
}