import 'farm_config.dart';

abstract class AnalyticsSink {
  void track(String event, Map<String, Object?> props);
}

class ConfigAnalyticsSink implements AnalyticsSink {
  const ConfigAnalyticsSink(this._config);

  final FarmConfig _config;

  @override
  void track(String event, Map<String, Object?> props) {
    _config.onAnalytics(event, {
      'app_id': _config.appId,
      'user_id': _config.userId,
      ...props,
    });
  }
}
