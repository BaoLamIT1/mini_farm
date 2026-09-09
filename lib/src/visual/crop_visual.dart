import 'package:flutter/widgets.dart';

abstract class CropVisual {
  /// stage: 0..stageCount-1 ; progress: 0..1
  Widget build(
    BuildContext context, {
    required String cropId,
    required int stage,
    required double progress,
    required double size,
  });

  /// Preload (atlas / .riv). v1 no-op.
  Future<void> warmUp() async {}
}
