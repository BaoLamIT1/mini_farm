import '../clock/game_clock.dart';
import '../config/crop_catalog.dart';
import '../config/land_catalog.dart';
import '../models/crop.dart';
import '../models/farm_state.dart';
import '../models/inventory.dart';
import '../models/plot.dart';
import 'growth_calculator.dart';
import 'unlock_rules.dart';

class Result<T> {
  final bool isOk;
  final T? value;
  final String? errorCode;

  const Result._(this.isOk, this.value, this.errorCode);

  factory Result.ok([T? value]) => Result._(true, value, null);
  factory Result.error(String code) => Result._(false, null, code);
}

class HarvestOutcome {
  final String cropId;
  final int qty;
  const HarvestOutcome({required this.cropId, required this.qty});
}

class OfflineReport {
  final int hoursAway;
  final int readyCount;
  const OfflineReport({required this.hoursAway, required this.readyCount});
}

class FarmEngine {
  FarmEngine(this._state, this._clock, {List<CropDef> catalog = CropCatalog.all})
      : _catalog = catalog;

  FarmState _state;
  final GameClock _clock;
  final List<CropDef> _catalog;

  FarmState get state => _state;

  CropDef? _cropById(String id) {
    for (final c in _catalog) {
      if (c.id == id) return c;
    }
    return null;
  }

  OfflineReport syncOffline() {
    var now = _clock.nowMs();
    if (now < _state.lastSeenMs) now = _state.lastSeenMs;
    final hoursAway = ((now - _state.lastSeenMs) / 3600000).floor();
    final readyCount = GrowthCalculator.readyCount(_state.plots, _catalog, now);
    _state = _state.copyWith(lastSeenMs: now);
    return OfflineReport(hoursAway: hoursAway, readyCount: readyCount);
  }

  Result<void> plant(int plotIndex, String cropId) {
    if (plotIndex < 0 || plotIndex >= _state.plots.length) {
      return Result.error('invalid_plot');
    }
    final def = _cropById(cropId);
    if (def == null) return Result.error('invalid_crop');
    if (!UnlockRules.isCropUnlocked(def, _state.totalEarned)) {
      return Result.error('crop_locked');
    }
    final plot = _state.plots[plotIndex];
    if (!plot.unlocked) return Result.error('plot_locked');
    if (plot.cropId != null) return Result.error('plot_occupied');

    final stats = Map<String, int>.from(_state.stats);
    final bankKey = 'seed_bank_$cropId';
    final banked = stats[bankKey] ?? 0;
    var coins = _state.coins;
    if (banked > 0) {
      stats[bankKey] = banked - 1;
    } else {
      if (coins < def.seedPrice) return Result.error('not_enough_coins');
      coins -= def.seedPrice;
    }
    stats['plantCount'] = (stats['plantCount'] ?? 0) + 1;

    final now = _clock.nowMs();
    final newPlots = List<Plot>.from(_state.plots);
    newPlots[plotIndex] = plot.copyWith(cropId: cropId, plantedAtMs: now);
    _state = _state.copyWith(coins: coins, plots: newPlots, stats: stats);
    return Result.ok(null);
  }

  Result<HarvestOutcome> harvest(int plotIndex) {
    if (plotIndex < 0 || plotIndex >= _state.plots.length) {
      return Result.error('invalid_plot');
    }
    final plot = _state.plots[plotIndex];
    if (plot.cropId == null) return Result.error('plot_empty');
    final def = _cropById(plot.cropId!);
    if (def == null) return Result.error('invalid_crop');
    final now = _clock.nowMs();
    if (plot.stateAt(now, def) != PlotState.ready) return Result.error('not_ready');

    final newInventory = Inventory.add(_state.inventory, plot.cropId!, def.yieldCount);
    final newPlots = List<Plot>.from(_state.plots);
    newPlots[plotIndex] = plot.copyWith(clearCrop: true);
    final stats = Map<String, int>.from(_state.stats);
    stats['harvestCount'] = (stats['harvestCount'] ?? 0) + 1;
    _state = _state.copyWith(plots: newPlots, inventory: newInventory, stats: stats);
    return Result.ok(HarvestOutcome(cropId: plot.cropId!, qty: def.yieldCount));
  }

  Result<int> sellAll(String cropId) {
    final def = _cropById(cropId);
    if (def == null) return Result.error('invalid_crop');
    final qty = _state.inventory[cropId] ?? 0;
    if (qty <= 0) return Result.error('no_inventory');

    final coinsGained = qty * def.sellPricePerUnit;
    final newInventory = Inventory.removeAll(_state.inventory, cropId);
    _state = _state.copyWith(
      coins: _state.coins + coinsGained,
      totalEarned: _state.totalEarned + coinsGained,
      inventory: newInventory,
    );
    return Result.ok(coinsGained);
  }

  Result<void> buyPlot(int plotIndex) {
    if (plotIndex < 0 || plotIndex >= _state.plots.length) {
      return Result.error('invalid_plot');
    }
    final plot = _state.plots[plotIndex];
    if (plot.unlocked) return Result.error('already_unlocked');
    final price = LandCatalog.priceFor(plotIndex);
    if (_state.coins < price) return Result.error('not_enough_coins');

    final newPlots = List<Plot>.from(_state.plots);
    newPlots[plotIndex] = plot.copyWith(unlocked: true);
    _state = _state.copyWith(coins: _state.coins - price, plots: newPlots);
    return Result.ok(null);
  }

  Result<void> buySeed(String cropId, int count) {
    if (count <= 0) return Result.error('invalid_count');
    final def = _cropById(cropId);
    if (def == null) return Result.error('invalid_crop');
    if (!UnlockRules.isCropUnlocked(def, _state.totalEarned)) {
      return Result.error('crop_locked');
    }
    final cost = def.seedPrice * count;
    if (_state.coins < cost) return Result.error('not_enough_coins');

    final stats = Map<String, int>.from(_state.stats);
    final bankKey = 'seed_bank_$cropId';
    stats[bankKey] = (stats[bankKey] ?? 0) + count;
    _state = _state.copyWith(coins: _state.coins - cost, stats: stats);
    return Result.ok(null);
  }

  List<CropDef> unlockedCrops() => UnlockRules.unlockedCrops(_catalog, _state.totalEarned);
}
