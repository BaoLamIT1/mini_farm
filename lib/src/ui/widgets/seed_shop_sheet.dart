import 'package:flutter/material.dart';

import '../../core/models/crop.dart';
import '../strings/farm_strings.dart';
import '../theme/farm_theme.dart';

/// Bottom sheet chọn hạt giống. Trả về [CropDef] được chọn, hoặc null nếu huỷ.
Future<CropDef?> showSeedShopSheet(
  BuildContext context, {
  required List<CropDef> unlockedCrops,
  required int coins,
}) {
  return showModalBottomSheet<CropDef>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(FarmDesignTokens.cardRadius)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(FarmStrings.shopTitle, style: FarmDesignTokens.titleTextStyle),
            const SizedBox(height: 12),
            ...unlockedCrops.map((crop) {
              final canAfford = coins >= crop.seedPrice;
              return ListTile(
                leading: const Icon(Icons.eco, color: Colors.green),
                title: Text(FarmStrings.cropLabel(crop.id)),
                subtitle: Text('Giá hạt: ${crop.seedPrice} · Chín sau ${_durationLabel(crop.growDuration)}'),
                enabled: canAfford,
                onTap: canAfford ? () => Navigator.of(context).pop(crop) : null,
              );
            }),
          ],
        ),
      ),
    ),
  );
}

String _durationLabel(Duration d) {
  if (d.inHours >= 1) return '${d.inHours} giờ';
  if (d.inMinutes >= 1) return '${d.inMinutes} phút';
  return '${d.inSeconds} giây';
}
