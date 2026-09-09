import 'package:flutter/material.dart';

import '../../integration/farm_config.dart';

/// Radius, spacing, text style nội bộ — tách khỏi [FarmTheme] công khai
/// (màu do host app truyền vào) để không phải sửa UI khi đổi design token.
class FarmDesignTokens {
  const FarmDesignTokens._();

  static const double plotRadius = 16;
  static const double cardRadius = 20;
  static const EdgeInsets screenPadding = EdgeInsets.all(16);
  static const TextStyle coinTextStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 18);
  static const TextStyle titleTextStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 22);
}

ThemeData buildFarmThemeData(FarmTheme theme) {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: theme.primaryColor,
    scaffoldBackgroundColor: theme.backgroundColor,
  );
}
