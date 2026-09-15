import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/clock/game_clock.dart';
import '../core/engine/farm_engine.dart';
import '../core/models/farm_state.dart';
import '../data/prefs_farm_repository.dart';
import '../integration/analytics_sink.dart';
import '../integration/farm_config.dart';
import 'widgets/coin_hud.dart';
import 'widgets/farm_map.dart';
import 'widgets/offline_report_dialog.dart';

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key, required this.config});

  final FarmConfig config;

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
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
    // Trả lại hướng dọc cho app host — v1 giả định host chạy portrait-only
    // (đa số app công ty hiện tại), xem README về giới hạn này khi nhúng.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // Khoá ngang trước khi dựng bản đồ, để FarmMapView đo đúng kích thước
    // khung nhìn sau khi xoay thay vì canh giữa hụt theo kích thước dọc cũ.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

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

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          const FarmMapView(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _FloatingBackButton(color: theme.primaryColor),
                  const Spacer(),
                  CoinHud(coins: engine.state.coins, currencyName: theme.currencyName),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút back nổi trên map (thay app bar) — vẫn dùng [BackButton] của Flutter
/// nên giữ đúng hành vi + tooltip "Back" mặc định (Navigator.maybePop, tự ẩn
/// khi không còn gì để pop).
class _FloatingBackButton extends StatelessWidget {
  const _FloatingBackButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!Navigator.canPop(context)) return const SizedBox.shrink();
    return Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: const BackButton(color: Colors.white),
    );
  }
}
