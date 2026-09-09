import 'package:flutter/material.dart';

import '../integration/farm_config.dart';
import 'strings/farm_strings.dart';
import 'theme/farm_theme.dart';

class MiniFarmEntryCard extends StatelessWidget {
  const MiniFarmEntryCard({super.key, required this.config, required this.onTap});

  final FarmConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = config.theme;
    return Material(
      color: theme.primaryColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(FarmDesignTokens.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FarmDesignTokens.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.primaryColor,
                radius: 24,
                child: const Icon(Icons.eco, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(theme.appName, style: FarmDesignTokens.titleTextStyle),
                    Text(
                      config.copyOverride?['entrySubtitle'] ?? FarmStrings.entrySubtitle,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
