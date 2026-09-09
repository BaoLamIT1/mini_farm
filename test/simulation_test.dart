// Mô phỏng 30 ngày chơi bằng một bot tham lam (luôn trồng cây lãi/phút cao
// nhất mà đủ tiền, luôn bán ngay khi thu hoạch, mua thêm ô đất khi rảnh tay)
// rồi in ra bảng tiến triển — xem spec §3.6 và DoD tuần 2.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_farm/src/core/clock/game_clock.dart';
import 'package:mini_farm/src/core/config/crop_catalog.dart';
import 'package:mini_farm/src/core/config/land_catalog.dart';
import 'package:mini_farm/src/core/engine/farm_engine.dart';
import 'package:mini_farm/src/core/models/farm_state.dart';
import 'package:mini_farm/src/core/models/plot.dart';

class _SimClock implements GameClock {
  int _ms = 0;
  @override
  int nowMs() => _ms;
  void set(int ms) => _ms = ms;
}

void main() {
  test('simulate 30 days of greedy play and print a progression table', () {
    const dayMs = 86400000;
    final checkpointDays = [1, 3, 7, 14, 30];
    final checkpoints = checkpointDays.map((d) => d * dayMs).toList();
    final endMs = checkpoints.last;

    final clock = _SimClock();
    final engine = FarmEngine(FarmState.initial(nowMs: 0), clock);

    final rows = <String>[];
    var nextCheckpointIdx = 0;

    void recordDue() {
      while (nextCheckpointIdx < checkpoints.length && clock.nowMs() >= checkpoints[nextCheckpointIdx]) {
        final day = checkpointDays[nextCheckpointIdx];
        final tier = engine.unlockedCrops().map((c) => c.tier).reduce(max);
        final plotsUnlocked = engine.state.plots.where((p) => p.unlocked).length;
        final harvests = engine.state.stats['harvestCount'] ?? 0;
        rows.add(
          'Day ${day.toString().padLeft(2)}: coins=${engine.state.coins.toString().padLeft(8)}  '
          'tier=$tier  plots=$plotsUnlocked  harvests=${harvests.toString().padLeft(4)}',
        );
        nextCheckpointIdx++;
      }
    }

    while (true) {
      // 1. Thu hoạch mọi ô đã chín rồi bán ngay.
      for (var i = 0; i < engine.state.plots.length; i++) {
        final plot = engine.state.plots[i];
        if (plot.cropId == null) continue;
        final def = CropCatalog.tryById(plot.cropId!);
        if (def == null) continue;
        if (plot.stateAt(clock.nowMs(), def) == PlotState.ready) {
          final harvestResult = engine.harvest(i);
          if (harvestResult.isOk) engine.sellAll(harvestResult.value!.cropId);
        }
      }

      // 2. Lấp mọi ô trống bằng cây lãi/phút cao nhất mà đủ tiền.
      var plantedSomething = true;
      while (plantedSomething) {
        plantedSomething = false;
        final byProfit = engine.unlockedCrops()
          ..sort((a, b) => b.profitPerMinute.compareTo(a.profitPerMinute));
        for (var i = 0; i < engine.state.plots.length; i++) {
          final plot = engine.state.plots[i];
          if (!plot.unlocked || plot.cropId != null) continue;
          for (final crop in byProfit) {
            if (engine.state.coins >= crop.seedPrice && engine.plant(i, crop.id).isOk) {
              plantedSomething = true;
              break;
            }
          }
        }
      }

      // 3. Nếu không còn ô trống để trồng, dồn tiền mở ô tiếp theo.
      final hasEmptyUnlocked = engine.state.plots.any((p) => p.unlocked && p.cropId == null);
      if (!hasEmptyUnlocked) {
        final nextLocked = engine.state.plots.indexWhere((p) => !p.unlocked);
        if (nextLocked != -1 && engine.state.coins >= LandCatalog.priceFor(nextLocked)) {
          engine.buyPlot(nextLocked);
        }
      }

      recordDue();
      if (nextCheckpointIdx >= checkpoints.length) break;

      // 4. Nhảy tới sự kiện tiếp theo (ô sắp chín gần nhất), kẹp bởi checkpoint kế tiếp.
      // Nếu không còn gì đang lớn (bế tắc), nhảy thẳng tới checkpoint kế tiếp.
      int? nextReadyAt;
      for (final plot in engine.state.plots) {
        if (plot.unlocked && plot.cropId != null) {
          final def = CropCatalog.tryById(plot.cropId!)!;
          final readyAt = plot.plantedAtMs! + def.growDuration.inMilliseconds;
          if (readyAt > clock.nowMs()) {
            nextReadyAt = nextReadyAt == null ? readyAt : min(nextReadyAt, readyAt);
          }
        }
      }

      var target = nextReadyAt ?? checkpoints[nextCheckpointIdx];
      if (checkpoints[nextCheckpointIdx] < target) target = checkpoints[nextCheckpointIdx];
      if (target <= clock.nowMs()) target = clock.nowMs() + 1;
      clock.set(min(target, endMs));
    }

    // ignore: avoid_print
    print('simulation_test — 30 ngày chơi liên tục:');
    for (final row in rows) {
      // ignore: avoid_print
      print(row);
    }

    expect(rows.length, checkpointDays.length);
    for (var i = 1; i < rows.length; i++) {
      expect(engine.state.coins, greaterThanOrEqualTo(0));
    }
    expect(engine.state.totalEarned, greaterThan(0));
    expect(engine.unlockedCrops().length, greaterThan(1));
    expect(engine.state.plots.where((p) => p.unlocked).length, greaterThanOrEqualTo(3));
  });
}
