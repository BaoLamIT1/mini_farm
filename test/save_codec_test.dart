import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_farm/src/core/models/farm_state.dart';
import 'package:mini_farm/src/core/persistence/save_codec.dart';

void main() {
  group('SaveCodec', () {
    test('encode then decode round-trips the state', () {
      final codec = SaveCodec('user_1');
      final state = FarmState.initial(nowMs: 12345, startingCoins: 42);

      final decoded = codec.decode(codec.encode(state));

      expect(decoded, isNotNull);
      expect(decoded!.coins, 42);
      expect(decoded.plots.length, 9);
    });

    test('tampering with the payload invalidates the HMAC', () {
      final codec = SaveCodec('user_1');
      final raw = codec.encode(FarmState.initial(nowMs: 0));

      final outer = jsonDecode(raw) as Map<String, dynamic>;
      (outer['d'] as Map<String, dynamic>)['coins'] = 999999;
      final tampered = jsonEncode(outer);

      expect(codec.decode(tampered), isNull);
    });

    test('garbage input decodes to null instead of throwing', () {
      final codec = SaveCodec('user_1');
      expect(codec.decode('not json at all'), isNull);
      expect(codec.decode('{}'), isNull);
    });

    test('a save is scoped to its userId secret', () {
      final saveA = SaveCodec('user_a').encode(FarmState.initial(nowMs: 0));
      expect(SaveCodec('user_b').decode(saveA), isNull);
    });
  });
}
