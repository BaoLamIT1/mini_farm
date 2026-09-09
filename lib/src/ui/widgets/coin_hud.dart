import 'package:flutter/material.dart';

import '../theme/farm_theme.dart';

class CoinHud extends StatelessWidget {
  const CoinHud({super.key, required this.coins, required this.currencyName});

  final int coins;
  final String currencyName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FarmDesignTokens.cardRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.amber, size: 22),
          const SizedBox(width: 6),
          Text('$coins $currencyName', style: FarmDesignTokens.coinTextStyle),
        ],
      ),
    );
  }
}
