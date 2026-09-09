import 'package:flutter_test/flutter_test.dart';
import 'package:mini_farm/src/core/config/crop_catalog.dart';
import 'package:mini_farm/src/core/engine/unlock_rules.dart';

void main() {
  group('UnlockRules', () {
    test('only radish unlocked at totalEarned 0', () {
      final unlocked = UnlockRules.unlockedCrops(CropCatalog.all, 0);
      expect(unlocked.map((c) => c.id), ['radish']);
    });

    test('tomato unlocks at the exact threshold (200)', () {
      expect(UnlockRules.isCropUnlocked(CropCatalog.byId('tomato'), 199), isFalse);
      expect(UnlockRules.isCropUnlocked(CropCatalog.byId('tomato'), 200), isTrue);
    });

    test('unlockedCrops grows monotonically with totalEarned', () {
      final at1000 = UnlockRules.unlockedCrops(CropCatalog.all, 1000).map((c) => c.id).toSet();
      expect(at1000, {'radish', 'tomato', 'corn'});
    });

    test('all crops unlocked at the top threshold', () {
      final all = UnlockRules.unlockedCrops(CropCatalog.all, 120000);
      expect(all.length, CropCatalog.all.length);
    });

    test('nextLockedCrop points to the cheapest still-locked crop', () {
      final next = UnlockRules.nextLockedCrop(CropCatalog.all, 0);
      expect(next?.id, 'tomato');
    });

    test('nextLockedCrop is null once everything is unlocked', () {
      expect(UnlockRules.nextLockedCrop(CropCatalog.all, 999999), isNull);
    });
  });
}
