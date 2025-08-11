import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';

class RuntimePreviewPage extends StatefulWidget {
  const RuntimePreviewPage({super.key, required this.mapData, required this.scene});

  final MapData mapData;
  final SceneData scene;

  @override
  State<RuntimePreviewPage> createState() => _RuntimePreviewPageState();
}

class _RuntimePreviewPageState extends State<RuntimePreviewPage> {
  final FocusNode _focusNode = FocusNode();
  int playerX = 2;
  int playerY = 2;
  String? message;
  bool actionRequested = false;
  String? lastStepKey; // to avoid retrigger on same tile
  final Set<String> executedAutorun = <String>{};
  Timer? _tick;

  static const double tileSize = 24.0;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) => _update());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _update() {
    // Autorun events
    for (final e in widget.mapData.events) {
      final key = 'Autorun:${e.x}:${e.y}';
      if (e.pages.isNotEmpty && e.pages.first.trigger == 'Autorun' && !executedAutorun.contains(key)) {
        executedAutorun.add(key);
        _runEvent(e);
      }
    }

    // PlayerTouch
    final stepKey = '${playerX}:${playerY}';
    if (stepKey != lastStepKey) {
      lastStepKey = stepKey;
      for (final e in widget.mapData.events) {
        if (e.x == playerX && e.y == playerY) {
          if (e.pages.isNotEmpty && e.pages.first.trigger == 'PlayerTouch') {
            _runEvent(e);
          }
        }
      }
    }

    // ActionButton
    if (actionRequested) {
      actionRequested = false;
      for (final e in widget.mapData.events) {
        if (e.x == playerX && e.y == playerY) {
          if (e.pages.isNotEmpty && e.pages.first.trigger == 'ActionButton') {
            _runEvent(e);
            break;
          }
        }
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _runEvent(EventData e) async {
    if (e.pages.isEmpty) return;
    final page = e.pages.first;
    for (final cmd in page.commands) {
      if (cmd.code == 'ShowText') {
        final text = (cmd.params['text'] ?? '').toString();
        setState(() => message = text);
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        setState(() => message = null);
      } else if (cmd.code == 'TransferPlayer') {
        final nx = (cmd.params['x'] ?? playerX) as int;
        final ny = (cmd.params['y'] ?? playerY) as int;
        setState(() {
          playerX = nx.clamp(0, widget.mapData.width - 1);
          playerY = ny.clamp(0, widget.mapData.height - 1);
        });
      }
    }
  }

  void _onKey(RawKeyEvent e) {
    if (e is! RawKeyDownEvent) return;
    final key = e.logicalKey;
    int dx = 0, dy = 0;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) dy = -1;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) dy = 1;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) dx = -1;
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) dx = 1;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) actionRequested = true;
    if (dx != 0 || dy != 0) {
      setState(() {
        playerX = (playerX + dx).clamp(0, widget.mapData.width - 1);
        playerY = (playerY + dy).clamp(0, widget.mapData.height - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.mapData;
    return Scaffold(
      appBar: AppBar(title: const Text('Aperçu Runtime')),
      body: RawKeyboardListener(
        autofocus: true,
        focusNode: _focusNode,
        onKey: _onKey,
        child: Stack(
          children: [
            Center(
              child: CustomPaint(
                size: Size(map.width * tileSize, map.height * tileSize),
                painter: _RuntimePainter(
                  mapData: map,
                  tileSize: tileSize,
                  playerX: playerX,
                  playerY: playerY,
                  scene: widget.scene,
                ),
              ),
            ),
            if (message != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuntimePainter extends CustomPainter {
  _RuntimePainter({
    required this.mapData,
    required this.tileSize,
    required this.playerX,
    required this.playerY,
    required this.scene,
  });

  final MapData mapData;
  final double tileSize;
  final int playerX;
  final int playerY;
  final SceneData scene;

  @override
  void paint(Canvas canvas, Size size) {
    final bgA = Paint()..color = const Color(0xFF153B6F);
    final bgB = Paint()..color = const Color(0xFF0F2F59);

    // background checker
    for (double y = 0; y < size.height; y += tileSize) {
      for (double x = 0; x < size.width; x += tileSize) {
        final isA = ((x / tileSize).floor() + (y / tileSize).floor()) % 2 == 0;
        canvas.drawRect(Rect.fromLTWH(x, y, tileSize, tileSize), isA ? bgA : bgB);
      }
    }

    // draw layers
    void paintLayer(TileLayer layer, Color color) {
      for (int y = 0; y < layer.height; y++) {
        for (int x = 0; x < layer.width; x++) {
          final t = layer.data[y][x];
          if (t < 0) continue;
          final r = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = color.withOpacity(0.35));
        }
      }
    }

    paintLayer(mapData.layers[MapLayerKind.layerA]!, const Color(0xFF64B5F6));
    paintLayer(mapData.layers[MapLayerKind.layerB]!, const Color(0xFF81C784));
    paintLayer(mapData.layers[MapLayerKind.layerC]!, const Color(0xFFA1887F));
    paintLayer(mapData.layers[MapLayerKind.layerD]!, const Color(0xFFBA68C8));

    // draw scene objects
    for (final o in scene.objects) {
      final rect = Rect.fromLTWH(o.x * tileSize, o.y * tileSize, tileSize, tileSize);
      final paint = Paint()..color = Colors.orangeAccent.withOpacity(0.9);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(4)), paint);
    }

    // draw player
    final playerCenter = Offset((playerX + 0.5) * tileSize, (playerY + 0.5) * tileSize);
    canvas.drawCircle(playerCenter, tileSize * 0.35, Paint()..color = Colors.white);
    canvas.drawCircle(playerCenter, tileSize * 0.35, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black54);
  }

  @override
  bool shouldRepaint(covariant _RuntimePainter oldDelegate) {
    return oldDelegate.mapData != mapData ||
        oldDelegate.playerX != playerX ||
        oldDelegate.playerY != playerY ||
        oldDelegate.scene != scene;
  }
}