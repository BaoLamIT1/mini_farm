import '../models/crop.dart';
import '../models/plot.dart';

class GrowthCalculator {
  const GrowthCalculator._();

  static CropDef? _defOf(Plot plot, List<CropDef> catalog) {
    if (plot.cropId == null) return null;
    for (final c in catalog) {
      if (c.id == plot.cropId) return c;
    }
    return null;
  }

  static int readyCount(List<Plot> plots, List<CropDef> catalog, int nowMs) {
    var count = 0;
    for (final p in plots) {
      final def = _defOf(p, catalog);
      if (def != null && p.stateAt(nowMs, def) == PlotState.ready) count++;
    }
    return count;
  }
}
