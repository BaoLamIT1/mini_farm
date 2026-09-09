import 'package:flutter_test/flutter_test.dart';
import 'package:mini_farm/src/core/config/crop_catalog.dart';
import 'package:mini_farm/src/core/engine/farm_engine.dart';
import 'package:mini_farm/src/core/clock/game_clock.dart';
import 'package:mini_farm/src/core/models/farm_state.dart';

class _FixedClock implements GameClock {
  _FixedClock(this._ms);
  int _ms;
  @override
  int nowMs() => _ms;
  void advance(Duration d) => _ms += d.inMilliseconds;
}

void main() {
  group('CropDef economy (spec §2.3)', () {
    test('radish profit/min matches table', () {
      final radish = CropCatalog.byId('radish');
      expect(radish.revenue, 16);
      expect(radish.profit, 6);
      expect(radish.profitPerMinute, closeTo(6.0, 0.01));
    });

    test('dragonfruit profit/min matches table', () {
      final dragonfruit = CropCatalog.byId('dragonfruit');
      expect(dragonfruit.revenue, 22000);
      expect(dragonfruit.profit, 12000);
      expect(dragonfruit.profitPerMinute, closeTo(16.7, 0.1));
    });

    test('profit/min increases with tier', () {
      final rates = CropCatalog.all.map((c) => c.profitPerMinute).toList();
      for (var i = 1; i < rates.length; i++) {
        expect(rates[i], greaterThan(rates[i - 1]));
      }
    });
  });

  group('FarmEngine plant/harvest/sell', () {
    late _FixedClock clock;
    late FarmEngine engine;

    setUp(() {
      clock = _FixedClock(0);
      engine = FarmEngine(FarmState.initial(nowMs: 0, startingCoins: 20), clock);
    });

    test('plant charges seed price and occupies plot', () {
      final result = engine.plant(0, 'radish');
      expect(result.isOk, isTrue);
      expect(engine.state.coins, 10);
      expect(engine.state.plots[0].cropId, 'radish');
    });

    test('plant fails with not_enough_coins', () {
      engine.plant(0, 'radish');
      engine.plant(1, 'radish');
      final result = engine.plant(2, 'radish'); // 20 - 10 - 10 = 0 left
      expect(result.isOk, isFalse);
      expect(result.errorCode, 'not_enough_coins');
    });

    test('plant fails on occupied plot', () {
      engine.plant(0, 'radish');
      final result = engine.plant(0, 'radish');
      expect(result.errorCode, 'plot_occupied');
    });

    test('plant fails on locked plot', () {
      final result = engine.plant(8, 'radish');
      expect(result.errorCode, 'plot_locked');
    });

    test('harvest before ready fails, after ready succeeds and fills inventory', () {
      engine.plant(0, 'radish');
      expect(engine.harvest(0).errorCode, 'not_ready');

      clock.advance(const Duration(minutes: 1));
      final result = engine.harvest(0);
      expect(result.isOk, isTrue);
      expect(result.value!.qty, 2);
      expect(engine.state.inventory['radish'], 2);
      expect(engine.state.plots[0].cropId, isNull);
    });

    test('sellAll pays out and updates totalEarned', () {
      engine.plant(0, 'radish');
      clock.advance(const Duration(minutes: 1));
      engine.harvest(0);

      final result = engine.sellAll('radish');
      expect(result.isOk, isTrue);
      expect(result.value, 16); // 2 * 8
      expect(engine.state.coins, 10 + 16);
      expect(engine.state.totalEarned, 16);
      expect(engine.state.inventory.containsKey('radish'), isFalse);
    });

    test('sellAll with empty inventory fails', () {
      final result = engine.sellAll('radish');
      expect(result.errorCode, 'no_inventory');
    });

    test('buyPlot unlocks a plot and charges its price', () {
      engine = FarmEngine(FarmState.initial(nowMs: 0, startingCoins: 500), clock);
      final result = engine.buyPlot(3);
      expect(result.isOk, isTrue);
      expect(engine.state.coins, 0);
      expect(engine.state.plots[3].unlocked, isTrue);
    });

    test('buyPlot on an already-unlocked plot fails', () {
      final result = engine.buyPlot(0);
      expect(result.errorCode, 'already_unlocked');
    });

    test('planting a locked crop fails', () {
      final result = engine.plant(0, 'tomato');
      expect(result.errorCode, 'crop_locked');
    });

    test('buySeed then plant consumes the banked seed without extra coin cost', () {
      engine = FarmEngine(FarmState.initial(nowMs: 0, startingCoins: 10), clock);
      expect(engine.buySeed('radish', 1).isOk, isTrue);
      expect(engine.state.coins, 0);
      expect(engine.plant(0, 'radish').isOk, isTrue);
      expect(engine.state.coins, 0); // no extra charge, seed came from bank
    });
  });
}
