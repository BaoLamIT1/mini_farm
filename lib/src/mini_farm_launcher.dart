import 'package:flutter/material.dart';

import 'core/clock/game_clock.dart';
import 'core/config/crop_catalog.dart';
import 'core/engine/growth_calculator.dart';
import 'data/prefs_farm_repository.dart';
import 'integration/farm_config.dart';
import 'ui/farm_screen.dart';
import 'ui/theme/farm_theme.dart';

class FarmBadge {
  final bool hasFarm;
  final int readyCount;

  const FarmBadge({required this.hasFarm, required this.readyCount});
}

class MiniFarm {
  const MiniFarm._();

  /// Mở game. Gọi từ onTap của entry card hoặc từ deeplink.
  static Route<void> route(FarmConfig config) {
    return MaterialPageRoute(
      builder: (context) => Theme(
        data: buildFarmThemeData(config.theme),
        child: FarmScreen(config: config),
      ),
    );
  }

  /// Cho host app hỏi trạng thái để badge trên entry card (VD: "3 cây đã chín").
  static Future<FarmBadge> badge(String userId, {String appId = 'default'}) async {
    final state = await const PrefsFarmRepository().load(appId, userId);
    if (state == null) return const FarmBadge(hasFarm: false, readyCount: 0);
    final readyCount = GrowthCalculator.readyCount(state.plots, CropCatalog.all, const SystemClock().nowMs());
    return FarmBadge(hasFarm: true, readyCount: readyCount);
  }
}
