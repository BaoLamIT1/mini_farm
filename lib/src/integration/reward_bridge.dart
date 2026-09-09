import 'farm_config.dart';

class RewardBridge {
  const RewardBridge(this._config);

  final FarmConfig _config;

  Future<RewardResult> grant(RewardPayload payload) async {
    final onReward = _config.onReward;
    if (onReward == null) return RewardResult.ok();
    return onReward(payload);
  }
}
