import 'package:flutter/material.dart';

class FarmTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final String currencyName;
  final String appName;
  final String? logoAssetPath;

  const FarmTheme({
    this.primaryColor = const Color(0xFF4CAF50),
    this.backgroundColor = const Color(0xFFE8F5E9),
    this.currencyName = 'Xu',
    this.appName = 'Nông Trại Mini',
    this.logoAssetPath,
  });
}

class RewardPayload {
  final String reason;
  final int amount;

  const RewardPayload({required this.reason, required this.amount});
}

class RewardResult {
  final bool success;
  final String? errorCode;

  const RewardResult._(this.success, this.errorCode);

  factory RewardResult.ok() => const RewardResult._(true, null);
  factory RewardResult.error(String code) => RewardResult._(false, code);
}

/// Event host app tự bắn vào để game thưởng coin (VD: user xem sản phẩm → +5 coin).
class HostAppEvent {
  final String type;
  final Map<String, Object?> props;

  const HostAppEvent(this.type, {this.props = const {}});
}

class FarmConfig {
  final String userId;
  final String appId;

  final FarmTheme theme;
  final Map<String, String>? copyOverride;

  final void Function(String event, Map<String, Object?> props) onAnalytics;

  final Future<RewardResult> Function(RewardPayload)? onReward;

  final Future<DateTime?> Function()? serverTime;

  final Stream<HostAppEvent>? hostEvents;

  const FarmConfig({
    required this.userId,
    required this.appId,
    this.theme = const FarmTheme(),
    this.copyOverride,
    required this.onAnalytics,
    this.onReward,
    this.serverTime,
    this.hostEvents,
  });
}
