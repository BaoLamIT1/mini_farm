import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/farm_state.dart';
import '../core/persistence/farm_repository.dart';
import '../core/persistence/save_codec.dart';

class PrefsFarmRepository implements FarmRepository {
  const PrefsFarmRepository();

  String _key(String appId, String userId) => 'mini_farm.v1.$appId.$userId';

  @override
  Future<FarmState?> load(String appId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(appId, userId));
    if (raw == null) return null;
    return SaveCodec(userId).decode(raw);
  }

  @override
  Future<void> save(String appId, String userId, FarmState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(appId, userId), SaveCodec(userId).encode(state));
  }
}
