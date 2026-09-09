import 'package:flutter/material.dart';

import 'crop_visual.dart';

/// v3 — chưa thêm dependency `package:rive` (giữ đúng §4.3: chỉ thêm khi
/// thật cần). Khi triển khai, artboard = cropId, state machine "growth",
/// input `stage` (0-4), `harvest` (trigger), `ready` (bool) — xem spec §5.4.
class RiveCropVisual implements CropVisual {
  const RiveCropVisual(this.riveAssetPath, {this.fallback = const _EmptyFallback()});

  final String riveAssetPath;
  final CropVisual fallback;

  @override
  Widget build(
    BuildContext context, {
    required String cropId,
    required int stage,
    required double progress,
    required double size,
  }) {
    return fallback.build(context, cropId: cropId, stage: stage, progress: progress, size: size);
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
