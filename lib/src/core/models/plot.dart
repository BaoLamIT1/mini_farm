import 'crop.dart';

enum PlotState { locked, empty, growing, ready }

class Plot {
  final int index;
  final bool unlocked;
  final String? cropId;
  final int? plantedAtMs;

  const Plot({
    required this.index,
    required this.unlocked,
    this.cropId,
    this.plantedAtMs,
  });

  bool get isEmpty => cropId == null;

  PlotState stateAt(int nowMs, CropDef? def) {
    if (!unlocked) return PlotState.locked;
    if (cropId == null || plantedAtMs == null || def == null) {
      return PlotState.empty;
    }
    return progressAt(nowMs, def) >= 1.0 ? PlotState.ready : PlotState.growing;
  }

  double progressAt(int nowMs, CropDef def) {
    if (plantedAtMs == null) return 0;
    final totalMs = def.growDuration.inMilliseconds;
    if (totalMs <= 0) return 1;
    final elapsed = nowMs - plantedAtMs!;
    return (elapsed / totalMs).clamp(0.0, 1.0);
  }

  int visualStageAt(int nowMs, CropDef def) {
    final stage = (progressAt(nowMs, def) * (def.stageCount - 1)).floor();
    return stage.clamp(0, def.stageCount - 1);
  }

  Plot copyWith({
    bool? unlocked,
    String? cropId,
    int? plantedAtMs,
    bool clearCrop = false,
  }) {
    return Plot(
      index: index,
      unlocked: unlocked ?? this.unlocked,
      cropId: clearCrop ? null : (cropId ?? this.cropId),
      plantedAtMs: clearCrop ? null : (plantedAtMs ?? this.plantedAtMs),
    );
  }

  Map<String, dynamic> toJson() => {
        'i': index,
        'u': unlocked,
        'c': cropId,
        'p': plantedAtMs,
      };

  factory Plot.fromJson(Map<String, dynamic> j) => Plot(
        index: j['i'] as int,
        unlocked: j['u'] as bool,
        cropId: j['c'] as String?,
        plantedAtMs: j['p'] as int?,
      );
}
