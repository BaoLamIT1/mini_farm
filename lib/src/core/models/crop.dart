class CropDef {
  final String id;
  final int tier;
  final int seedPrice;
  final Duration growDuration;
  final int yieldCount;
  final int sellPricePerUnit;
  final int stageCount;
  final int unlockAtTotalEarned;

  const CropDef({
    required this.id,
    required this.tier,
    required this.seedPrice,
    required this.growDuration,
    required this.yieldCount,
    required this.sellPricePerUnit,
    this.stageCount = 5,
    required this.unlockAtTotalEarned,
  });

  int get revenue => yieldCount * sellPricePerUnit;
  int get profit => revenue - seedPrice;
  double get profitPerMinute => profit / growDuration.inSeconds * 60;
}
