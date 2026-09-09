import '../models/crop.dart';

class UnlockRules {
  const UnlockRules._();

  static bool isCropUnlocked(CropDef def, int totalEarned) =>
      totalEarned >= def.unlockAtTotalEarned;

  static List<CropDef> unlockedCrops(List<CropDef> catalog, int totalEarned) =>
      catalog.where((c) => isCropUnlocked(c, totalEarned)).toList();

  static CropDef? nextLockedCrop(List<CropDef> catalog, int totalEarned) {
    final locked = catalog.where((c) => !isCropUnlocked(c, totalEarned)).toList()
      ..sort((a, b) => a.unlockAtTotalEarned.compareTo(b.unlockAtTotalEarned));
    return locked.isEmpty ? null : locked.first;
  }
}
