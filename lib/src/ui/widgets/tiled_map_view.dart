import 'dart:async';

import 'package:flutter/material.dart';

import '../layout/tiled_map.dart';

/// Vẽ một [TiledMap] đã load (nền nông trại thiết kế bằng Tiled) lên đúng
/// khung [width]x[height]. Animation tile (nước, v.v.) tick theo thời gian
/// thật, refresh mỗi 100ms — đủ mịn cho duration animation cỡ 100ms/frame mà
/// không phải repaint 60 lần/giây như animation UI thông thường.
class TiledMapView extends StatefulWidget {
  const TiledMapView({super.key, required this.assetPath, required this.width, required this.height});

  final String assetPath;
  final double width;
  final double height;

  @override
  State<TiledMapView> createState() => _TiledMapViewState();
}

class _TiledMapViewState extends State<TiledMapView> {
  static final Map<String, Future<TiledMap>> _cache = {};

  TiledMap? _map;
  Timer? _ticker;
  final _stopwatch = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    final future = _cache.putIfAbsent(widget.assetPath, () => TiledMap.loadFromAssets(widget.assetPath));
    future.then((map) {
      if (!mounted) return;
      setState(() => _map = map);
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = _map;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: map == null ? null : CustomPaint(painter: _TiledMapPainter(map, _stopwatch.elapsedMilliseconds)),
    );
  }
}

class _TiledMapPainter extends CustomPainter {
  _TiledMapPainter(this.map, this.elapsedMs);

  final TiledMap map;
  final int elapsedMs;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / map.pixelWidth;
    final scaleY = size.height / map.pixelHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final dx = (size.width - map.pixelWidth * scale) / 2;
    final dy = (size.height - map.pixelHeight * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final paint = Paint()..filterQuality = FilterQuality.none;
    for (final layer in map.layers) {
      for (var i = 0; i < layer.gids.length; i++) {
        final rawGid = layer.gids[i];
        if (rawGid == 0) continue;
        final resolved = map.resolveGid(rawGid);
        if (resolved == null) continue;
        final (tileset, localId) = resolved;
        final src = tileset.srcRectFor(tileset.frameAt(localId, elapsedMs));
        final col = i % layer.width;
        final row = i ~/ layer.width;
        // Vẽ theo kích thước tile thật của tileset (có thể lớn hơn lưới ô
        // của map, vd tileset 64x64 đặt trên map lưới 16x16) — Tiled neo tile
        // vào góc dưới-trái của ô, tile to hơn sẽ tràn lên trên/sang phải.
        final tileWidth = tileset.tileWidth.toDouble();
        final tileHeight = tileset.tileHeight.toDouble();
        final left = col * map.tileWidth.toDouble();
        final bottom = (row + 1) * map.tileHeight.toDouble();
        final dst = Rect.fromLTWH(left, bottom - tileHeight, tileWidth, tileHeight);
        canvas.drawImageRect(tileset.image, src, dst, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TiledMapPainter oldDelegate) => oldDelegate.elapsedMs != elapsedMs || oldDelegate.map != map;
}
