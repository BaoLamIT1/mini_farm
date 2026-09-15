import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'plant_sprite.dart';
import 'tiled_map_view.dart';

const _tiledAssetPath = 'assets/tiled/mini_farm.tmj';
// Map Tiled gốc 48x48 ô 16px = 768x768px — hiển thị ở 2x cho rõ trên di động.
const _mapWidth = 1536.0;
const _mapHeight = 1536.0;
const _nativeTile = 16.0;
const _displayScale = _mapWidth / (48 * _nativeTile); // = 2.0

// Tâm 8 ô đất của "Soil Plots Layer" (id=5) trong mini_farm.tmj — mỗi ô là 1
// mảng đất 4x4 tile, góc trên-trái tại các toạ độ lưới gốc (col,row) dưới
// đây (đọc trực tiếp từ .tmj, xem gid viền 3284/3286/3508/3510). Demo tạm
// đặt cây cố định vào tâm mỗi ô — hệ trồng cây thật sẽ tính theo state game.
const _soilPlotTopLeftTiles = [
  (29, 13),
  (34, 13),
  (39, 13),
  (44, 13),
  (29, 17),
  (34, 17),
  (39, 17),
  (44, 17),
];
const _soilPlotSizeTiles = 0;

// Điểm neo đáy (giữa cạnh dưới) của từng ô đất — cây to nhỏ khác nhau đều
// "mọc" từ cùng 1 mặt đất nên neo đáy hợp lý hơn neo tâm.
List<Offset> _soilPlotBottomCenters() => [
  for (final (col, row) in _soilPlotTopLeftTiles)
    Offset(
      (col + _soilPlotSizeTiles / 2) * _nativeTile * _displayScale,
      (row + _soilPlotSizeTiles) * _nativeTile * _displayScale,
    ),
];

// 5 giai đoạn lớn của Plant_001.png (sheet 256x64) — sheet này KHÔNG phải
// lưới đều 16px như Plants.png (5 sprite nằm ở toạ độ pixel lệch nhau, xem
// trả lời trong hội thoại), nên toạ độ dưới đây là bounding-box pixel thật
// (quét kênh alpha để tìm, không đoán bằng mắt nữa) + đệm 2px mỗi cạnh —
// tile=1.0 nghĩa là col/row/colSpan/rowSpan ở đây tính thẳng bằng px.
const _plantSheetPath = 'assets/tiled/Plant_001.png';
const _plantSheetWidth = 256.0;
const _plantSheetHeight = 64.0;
const _plantTile = 1.0;
const _plantStages = [
  (col: 3.0, row: 41.0, colSpan: 21.0, rowSpan: 23.0),
  (col: 29.0, row: 32.0, colSpan: 34.0, rowSpan: 32.0),
  (col: 75.0, row: 14.0, colSpan: 36.0, rowSpan: 50.0),
  (col: 131.0, row: 0.0, colSpan: 55.0, rowSpan: 64.0),
  (col: 195.0, row: 0.0, colSpan: 55.0, rowSpan: 64.0),
];

/// Bản đồ nông trại kéo/zoom được — [InteractiveViewer] bao nền vẽ từ map
/// Tiled ([TiledMapView]). Lớp trồng/thu hoạch (ô đất, cây) sẽ làm lại riêng
/// bằng Rive/sprite sau, nên widget này hiện chỉ còn thuần phần xem bản đồ.
class FarmMapView extends StatefulWidget {
  const FarmMapView({super.key});

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

  // Canh giữa bản đồ vào khung nhìn ở đúng scale "phủ kín" (cover) đúng 1 lần
  // khi mở màn — sau đó để yên vị trí người chơi đang kéo tới.
  void _centerOnce(Size viewport, double scale) {
    if (_centered) return;
    _centered = true;
    final tx = (viewport.width - _mapWidth * scale) / 2;
    final ty = (viewport.height - _mapHeight * scale) / 2;
    _controller.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        // minScale = scale nhỏ nhất mà map vẫn phủ kín khung nhìn (không hở
        // viền trắng khi kéo/zoom hết cỡ) — maxScale giới hạn zoom vào tối đa
        // gấp đôi mức đó, tránh vỡ nét pixel art khi phóng quá to.
        final coverScale = math.max(
          viewport.width / _mapWidth,
          viewport.height / _mapHeight,
        );
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _centerOnce(viewport, coverScale),
        );
        return InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          boundaryMargin: EdgeInsets.zero,
          minScale: coverScale,
          maxScale: coverScale * 2,
          child: SizedBox(
            width: _mapWidth,
            height: _mapHeight,
            child: Stack(
              children: [
                const TiledMapView(
                  assetPath: _tiledAssetPath,
                  width: _mapWidth,
                  height: _mapHeight,
                ),
                ..._buildDemoPlants(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Demo: rải đủ 5 giai đoạn lớn của Plant_001 qua 8 ô đất (lặp lại nếu dư ô)
  // để xem 1 lượt tất cả các cỡ cây có cắt/neo đúng không.
  List<Widget> _buildDemoPlants() {
    final centers = _soilPlotBottomCenters();
    return [
      for (var i = 0; i < centers.length; i++)
        _buildDemoPlant(centers[i], _plantStages[i % _plantStages.length]),
    ];
  }

  Widget _buildDemoPlant(
    Offset bottomCenter,
    ({double col, double row, double colSpan, double rowSpan}) stage,
  ) {
    final width = stage.colSpan * _plantTile * _displayScale;
    final height = stage.rowSpan * _plantTile * _displayScale;
    return Positioned(
      left: bottomCenter.dx - width / 2,
      top: bottomCenter.dy - height,
      width: width,
      height: height,
      child: PlantSprite(
        assetPath: _plantSheetPath,
        sheetWidth: _plantSheetWidth,
        sheetHeight: _plantSheetHeight,
        tile: _plantTile,
        col: stage.col,
        row: stage.row,
        colSpan: stage.colSpan,
        rowSpan: stage.rowSpan,
        pixelScale: _displayScale,
      ),
    );
  }
}
