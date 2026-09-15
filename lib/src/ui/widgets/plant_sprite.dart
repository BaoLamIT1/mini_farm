import 'package:flutter/material.dart';

/// Cắt 1 vùng (có thể gộp nhiều ô, vì cây lớn dần chiếm nhiều ô hơn) ra khỏi
/// 1 sprite sheet dạng lưới NxM ô [tile]px, vẽ đúng tỉ lệ pixel gốc (không
/// kéo giãn méo) — dùng OverflowBox dịch ảnh để lộ đúng vùng cần, khỏi phải
/// tự decode/crop ảnh bằng tay.
///
/// Demo tạm để xem thử cây trên map — hệ trồng cây thật (chọn stage theo
/// tiến độ lớn thật của cây) sẽ làm lại bằng Rive hoặc sprite animation sau.
class PlantSprite extends StatelessWidget {
  const PlantSprite({
    super.key,
    required this.assetPath,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.tile,
    required this.col,
    required this.row,
    required this.colSpan,
    required this.rowSpan,
    required this.pixelScale,
  });

  /// Đường dẫn asset sprite sheet.
  final String assetPath;

  /// Kích thước gốc (px) của cả sheet.
  final double sheetWidth;
  final double sheetHeight;

  /// Kích thước 1 ô lưới (px), vd 16.
  final double tile;

  /// Vùng cần cắt, tính theo đơn vị ô lưới — góc trên-trái tại (col,row),
  /// rộng [colSpan] ô, cao [rowSpan] ô (cây càng lớn càng chiếm nhiều ô).
  final double col;
  final double row;
  final double colSpan;
  final double rowSpan;

  /// Hệ số phóng từ pixel gốc sang pixel hiển thị (vd 2.0 = giữ đúng tỉ lệ
  /// 2x đang dùng cho map Tiled).
  final double pixelScale;

  @override
  Widget build(BuildContext context) {
    final width = colSpan * tile * pixelScale;
    final height = rowSpan * tile * pixelScale;
    return ClipRect(
      child: SizedBox(
        width: width,
        height: height,
        child: OverflowBox(
          maxWidth: sheetWidth * pixelScale,
          maxHeight: sheetHeight * pixelScale,
          alignment: Alignment.topLeft,
          child: Transform.translate(
            offset: Offset(-col * tile * pixelScale, -row * tile * pixelScale),
            child: Image.asset(
              assetPath,
              width: sheetWidth * pixelScale,
              height: sheetHeight * pixelScale,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }
}
