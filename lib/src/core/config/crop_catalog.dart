import '../models/crop.dart';

class CropCatalog {
  const CropCatalog._();

  static const List<CropDef> all = [
    CropDef(
      id: 'radish',
      tier: 1,
      seedPrice: 10,
      growDuration: Duration(minutes: 1),
      yieldCount: 2,
      sellPricePerUnit: 8,
      unlockAtTotalEarned: 0,
    ),
    CropDef(
      id: 'tomato',
      tier: 2,
      seedPrice: 50,
      growDuration: Duration(minutes: 5),
      yieldCount: 3,
      sellPricePerUnit: 30,
      unlockAtTotalEarned: 200,
    ),
    CropDef(
      id: 'corn',
      tier: 3,
      seedPrice: 200,
      growDuration: Duration(minutes: 15),
      yieldCount: 3,
      sellPricePerUnit: 110,
      unlockAtTotalEarned: 1000,
    ),
    CropDef(
      id: 'pumpkin',
      tier: 4,
      seedPrice: 800,
      growDuration: Duration(hours: 1),
      yieldCount: 3,
      sellPricePerUnit: 500,
      unlockAtTotalEarned: 5000,
    ),
    CropDef(
      id: 'grape',
      tier: 5,
      seedPrice: 3000,
      growDuration: Duration(hours: 4),
      yieldCount: 4,
      sellPricePerUnit: 1500,
      unlockAtTotalEarned: 25000,
    ),
    CropDef(
      id: 'dragonfruit',
      tier: 6,
      seedPrice: 10000,
      growDuration: Duration(hours: 12),
      yieldCount: 4,
      sellPricePerUnit: 5500,
      unlockAtTotalEarned: 120000,
    ),
  ];

  static CropDef? tryById(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  static CropDef byId(String id) => tryById(id)!;
}
