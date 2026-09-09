import 'package:flutter/material.dart';

import 'crop_visual.dart';

/// v2 — dùng khi có sprite thật theo hợp đồng asset ở spec §5.3
/// (`crop_{cropId}_stage{n}.png`, 256×256, pivot bottom-center).
/// Rơi về icon nếu asset chưa tồn tại, để có thể bật từng cây một qua
/// [VisualRegistry] mà không vỡ UI.
class SpriteCropVisual implements CropVisual {
  const SpriteCropVisual({this.fallback = const _EmptyFallback()});

  final CropVisual fallback;

  String _assetFor(String cropId, int stage) => 'assets/sprites/crops/crop_${cropId}_stage$stage.png';

  @override
  Widget build(
    BuildContext context, {
    required String cropId,
    required int stage,
    required double progress,
    required double size,
  }) {
    return Image.asset(
      _assetFor(cropId, stage),
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) => fallback.build(
        context,
        cropId: cropId,
        stage: stage,
        progress: progress,
        size: size,
      ),
    );
  }

  @override
  Future<void> warmUp() async {}
}

class _EmptyFallback implements CropVisual {
  const _EmptyFallback();

  @override
  Widget build(
    BuildContext context, {
    required String cropId,
    required int stage,
    required double progress,
    required double size,
  }) =>
      SizedBox(width: size, height: size);

  @override
  Future<void> warmUp() async {}
}
