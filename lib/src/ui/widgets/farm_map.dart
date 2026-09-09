import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/config/crop_catalog.dart';
import '../../core/config/land_catalog.dart';
import '../../core/models/plot.dart';
import '../../visual/visual_registry.dart';
import 'plot_tile.dart';

const _mapWidth = 900.0;
const _mapHeight = 760.0;
const _tileSize = 108.0;

// Vị trí 9 ô đất trong sân vườn — cố tình lệch nhẹ khỏi lưới cứng cho giống
// bố cục vườn thật, thay vì bảng ô vuông đều tăm tắp.
const _plotOffsets = [
  Offset(150, 120), Offset(380, 100), Offset(610, 130),
  Offset(180, 340), Offset(410, 320), Offset(640, 350),
  Offset(150, 560), Offset(380, 540), Offset(610, 570),
];

final _grassDots = List.generate(70, (i) {
  final r = Random(1000 + i);
  return Offset(r.nextDouble(), r.nextDouble());
});

/// Bản đồ nông trại kéo/zoom được (kiểu Nông Trại Vui Vẻ) — [InteractiveViewer]
/// bao một canvas lớn hơn màn hình, các ô đất nằm ở vị trí cố định trên đó
/// thay vì trong lưới GridView.
class FarmMapView extends StatefulWidget {
  const FarmMapView({
    super.key,
    required this.plots,
    required this.nowMs,
    required this.registry,
    required this.onTapPlot,
  });

  final List<Plot> plots;
  final int nowMs;
  final VisualRegistry registry;
  final void Function(int index) onTapPlot;

  @override
  State<FarmMapView> createState() => _FarmMapViewState();
}

class _FarmMapViewState extends State<FarmMapView> {
  final _controller = TransformationController();
  bool _centered = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Canh giữa bản đồ vào khung nhìn đúng 1 lần khi mở màn — sau đó để yên
  // vị trí người chơi đang kéo tới, kể cả khi ticker 1s ở FarmScreen rebuild.
  void _centerOnce(Size viewport) {
    if (_centered) return;
    _centered = true;
    final dx = ((_mapWidth - viewport.width) / 2).clamp(0.0, _mapWidth);
    final dy = ((_mapHeight - viewport.height) / 2).clamp(0.0, _mapHeight);
    _controller.value = Matrix4.translationValues(-dx, -dy, 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnce(constraints.biggest));
        return InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(160),
          minScale: 0.5,
          maxScale: 2.2,
          child: SizedBox(
            width: _mapWidth,
            height: _mapHeight,
            child: Stack(
              children: [
                _buildGround(),
                ..._buildFence(),
                _decor(const Offset(40, 30), Icons.cottage, 56),
                _decor(const Offset(_mapWidth - 100, 40), Icons.park, 44),
                _decor(const Offset(40, _mapHeight - 110), Icons.forest, 44),
                _decor(const Offset(_mapWidth - 110, _mapHeight - 120), Icons.park, 48),
                for (var i = 0; i < widget.plots.length && i < _plotOffsets.length; i++) _buildPlot(i),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGround() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade300, Colors.green.shade500],
          ),
        ),
        child: CustomPaint(painter: _GrassTexturePainter(_grassDots)),
      ),
    );
  }

  List<Widget> _buildFence() {
    final posts = <Widget>[];
    const spacing = 70.0;
    for (var x = 0.0; x < _mapWidth; x += spacing) {
      posts.add(_fencePost(Offset(x, -18)));
      posts.add(_fencePost(Offset(x, _mapHeight - 14)));
    }
    for (var y = 0.0; y < _mapHeight; y += spacing) {
      posts.add(_fencePost(Offset(-18, y)));
      posts.add(_fencePost(Offset(_mapWidth - 14, y)));
    }
    return posts;
  }

  Widget _fencePost(Offset offset) => Positioned(
        left: offset.dx,
        top: offset.dy,
        child: Icon(Icons.fence, size: 26, color: Colors.brown.shade700),
      );

  Widget _decor(Offset offset, IconData icon, double size) => Positioned(
        left: offset.dx,
        top: offset.dy,
        child: Icon(icon, size: size, color: Colors.brown.shade800),
      );

  Widget _buildPlot(int index) {
    final plot = widget.plots[index];
    final offset = _plotOffsets[index];
    final cropDef = plot.cropId == null ? null : CropCatalog.tryById(plot.cropId!);
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: _tileSize,
      height: _tileSize,
      child: PlotTile(
        plot: plot,
        cropDef: cropDef,
        nowMs: widget.nowMs,
        registry: widget.registry,
        landPrice: LandCatalog.priceFor(index),
        onTap: () => widget.onTapPlot(index),
      ),
    );
  }
}

class _GrassTexturePainter extends CustomPainter {
  const _GrassTexturePainter(this.dots);
  final List<Offset> dots;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green.shade700.withValues(alpha: 0.35);
    for (final d in dots) {
      canvas.drawCircle(Offset(d.dx * size.width, d.dy * size.height), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrassTexturePainter oldDelegate) => false;
}
