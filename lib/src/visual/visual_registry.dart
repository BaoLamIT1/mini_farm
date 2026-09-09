import 'crop_visual.dart';

class VisualRegistry {
  final CropVisual fallback;
  final Map<String, CropVisual> overrides;

  const VisualRegistry({required this.fallback, this.overrides = const {}});

  CropVisual forCrop(String cropId) => overrides[cropId] ?? fallback;
}
