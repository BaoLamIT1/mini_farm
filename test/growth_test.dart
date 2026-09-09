import 'package:flutter_test/flutter_test.dart';
import 'package:mini_farm/src/core/config/crop_catalog.dart';
import 'package:mini_farm/src/core/engine/growth_calculator.dart';
import 'package:mini_farm/src/core/models/plot.dart';

void main() {
  final radish = CropCatalog.byId('radish'); // 1 phút, 5 stage mặc định

  group('Plot.stateAt', () {
    test('unplanted unlocked plot is empty', () {
      const plot = Plot(index: 0, unlocked: true);
      expect(plot.stateAt(0, null), PlotState.empty);
    });

    test('locked plot stays locked regardless of crop', () {
      const plot = Plot(index: 8, unlocked: false);
      expect(plot.stateAt(0, null), PlotState.locked);
    });

    test('growing then ready as time passes', () {
      final plot = Plot(index: 0, unlocked: true, cropId: 'radish', plantedAtMs: 0);
      expect(plot.stateAt(30000, radish), PlotState.growing);
      expect(plot.stateAt(60000, radish), PlotState.ready);
      expect(plot.stateAt(120000, radish), PlotState.ready); // vẫn ready, không tự mất
    });
  });

  group('Plot.progressAt / visualStageAt', () {
    test('progress clamps to [0,1]', () {
      final plot = Plot(index: 0, unlocked: true, cropId: 'radish', plantedAtMs: 0);
      expect(plot.progressAt(0, radish), 0.0);
      expect(plot.progressAt(30000, radish), closeTo(0.5, 0.001));
      expect(plot.progressAt(999999, radish), 1.0);
    });

    test('visual stage maps progress into stageCount buckets', () {
      final plot = Plot(index: 0, unlocked: true, cropId: 'radish', plantedAtMs: 0);
      expect(plot.visualStageAt(0, radish), 0);
      expect(plot.visualStageAt(60000, radish), radish.stageCount - 1);
    });
  });

  group('GrowthCalculator.readyCount', () {
    test('counts only plots that are actually ready', () {
      final plots = [
        Plot(index: 0, unlocked: true, cropId: 'radish', plantedAtMs: 0), // ready at 60s
        Plot(index: 1, unlocked: true, cropId: 'radish', plantedAtMs: 50000), // not ready yet
        const Plot(index: 2, unlocked: true), // empty
      ];
      expect(GrowthCalculator.readyCount(plots, CropCatalog.all, 60000), 1);
    });
  });
}
