import 'package:flutter/material.dart';

import 'crop_visual.dart';

class IconCropVisual implements CropVisual {
  const IconCropVisual();

  static const _icons = {
    'radish': Icons.grass,
    'tomato': Icons.local_florist,
    'corn': Icons.eco,
    'pumpkin': Icons.spa,
    'grape': Icons.wine_bar,
    'dragonfruit': Icons.filter_vintage,
  };

  @override
  Widget build(
    BuildContext context, {
    required String cropId,
    required int stage,
    required double progress,
    required double size,
  }) {
    final t = progress.clamp(0.0, 1.0);
    return AnimatedScale(
      scale: 0.35 + 0.65 * t,
      duration: const Duration(milliseconds: 200),
      child: Opacity(
        opacity: 0.45 + 0.55 * t,
        child: Icon(
          _icons[cropId] ?? Icons.eco,
          size: size,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  @override
  Future<void> warmUp() async {}
}
