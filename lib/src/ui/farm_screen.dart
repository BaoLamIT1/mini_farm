import 'dart:async';

import 'package:flutter/material.dart';

import '../core/clock/game_clock.dart';
import '../core/config/crop_catalog.dart';
import '../core/engine/farm_engine.dart';
import '../core/models/farm_state.dart';
import '../core/models/plot.dart';
import '../data/prefs_farm_repository.dart';
import '../integration/analytics_sink.dart';
import '../integration/farm_config.dart';
import '../visual/icon_crop_visual.dart';
import '../visual/visual_registry.dart';
import 'strings/farm_strings.dart';
import 'widgets/coin_hud.dart';
import 'widgets/farm_map.dart';
import 'widgets/harvest_burst.dart';
import 'widgets/offline_report_dialog.dart';
import 'widgets/seed_shop_sheet.dart';

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key, required this.config});

  final FarmConfig config;

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  static const _registry = VisualRegistry(fallback: IconCropVisual());

  final _repo = const PrefsFarmRepository();
  final _clock = OffsetGameClock();
  late final ConfigAnalyticsSink _analytics = ConfigAnalyticsSink(widget.config);

  FarmEngine? _engine;
  Timer? _ticker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final serverTime = widget.config.serverTime;
    if (serverTime != null) {
      final now = await serverTime();
      if (now != null) {
        _clock.offsetMs = now.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
      }
    }

    final saved = await _repo.load(widget.config.appId, widget.config.userId);
    final isFirstOpen = saved == null;
    final initialState = saved ?? FarmState.initial(nowMs: _clock.nowMs());
    final engine = FarmEngine(initialState, _clock);
    final offlineReport = engine.syncOffline();

    _analytics.track(isFirstOpen ? 'farm_first_open' : 'farm_open', {});
    await _persist(engine.state);

    if (!mounted) return;
    setState(() {
      _engine = engine;
      _loading = false;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    if (offlineReport.readyCount > 0) {
      _analytics.track('farm_offline_report', {
        'hours_away': offlineReport.hoursAway,
        'ready_count': offlineReport.readyCount,
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showOfflineReportDialog(context, offlineReport);
      });
    }
  }

  Future<void> _persist(FarmState state) {
    return _repo.save(widget.config.appId, widget.config.userId, state);
  }

  void _showError(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(FarmStrings.errorFor(code)), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _onTapPlot(int index) async {
    final engine = _engine;
    if (engine == null) return;
    final nowMs = _clock.nowMs();
    final plot = engine.state.plots[index];
    final cropDef = plot.cropId == null ? null : CropCatalog.tryById(plot.cropId!);
    final state = plot.stateAt(nowMs, cropDef);

    switch (state) {
      case PlotState.locked:
        final result = engine.buyPlot(index);
        if (result.isOk) {
          _analytics.track('farm_buy_plot', {'plot_index': index});
          await _persist(engine.state);
        } else {
          _showError(result.errorCode!);
        }
        setState(() {});
      case PlotState.empty:
        final unlocked = engine.unlockedCrops();
        final selected = await showSeedShopSheet(
          context,
          unlockedCrops: unlocked,
          coins: engine.state.coins,
        );
        if (selected == null) return;
        final result = engine.plant(index, selected.id);
        if (result.isOk) {
          _analytics.track('farm_plant', {'crop_id': selected.id, 'plot_index': index});
          await _persist(engine.state);
        } else {
          _showError(result.errorCode!);
        }
        setState(() {});
      case PlotState.growing:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cây chưa chín, quay lại sau nhé'), duration: Duration(seconds: 1)),
        );
      case PlotState.ready:
        final harvestResult = engine.harvest(index);
        if (!harvestResult.isOk) {
          _showError(harvestResult.errorCode!);
          return;
        }
        final outcome = harvestResult.value!;
        final sellResult = engine.sellAll(outcome.cropId);
        final coinsGained = sellResult.isOk ? sellResult.value! : 0;
        _analytics.track('farm_harvest', {'crop_id': outcome.cropId, 'coins_gained': coinsGained});
        showHarvestBurst(context, coins: coinsGained);
        await _persist(engine.state);
        setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.config.theme;
    if (_loading || _engine == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
      );
    }

    final engine = _engine!;
    final nowMs = _clock.nowMs();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text(theme.appName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: CoinHud(coins: engine.state.coins, currencyName: theme.currencyName)),
          ),
        ],
      ),
      body: FarmMapView(
        plots: engine.state.plots,
        nowMs: nowMs,
        registry: _registry,
        onTapPlot: _onTapPlot,
      ),
    );
  }
}
