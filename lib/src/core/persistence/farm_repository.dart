import '../models/farm_state.dart';

abstract class FarmRepository {
  Future<FarmState?> load(String appId, String userId);
  Future<void> save(String appId, String userId, FarmState state);
}
