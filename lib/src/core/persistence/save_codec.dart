import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/farm_state.dart';

/// HMAC chỉ chặn sửa tay file JSON, không chống reverse engineering.
/// Đủ cho v1 vì thưởng không có giá trị tiền thật (xem spec §6.2).
class SaveCodec {
  SaveCodec(String userId) : _secret = '$_staticSecret:$userId';

  static const _staticSecret = 'mini_farm_v1_static_secret';
  final String _secret;

  String encode(FarmState s) {
    final data = s.toJson();
    final payload = jsonEncode(data);
    final digest = _sign(payload);
    return jsonEncode({'v': s.schemaVersion, 'd': data, 'h': digest});
  }

  FarmState? decode(String raw) {
    try {
      final outer = jsonDecode(raw) as Map<String, dynamic>;
      final data = outer['d'] as Map<String, dynamic>;
      final payload = jsonEncode(data);
      if (_sign(payload) != outer['h']) return null;
      return FarmState.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  String _sign(String payload) =>
      Hmac(sha256, utf8.encode(_secret)).convert(utf8.encode(payload)).toString();
}
