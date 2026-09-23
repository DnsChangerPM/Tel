// Tel — «ویرایشگر متن تلگرام»
//
// پوستهٔ برنامه. عمداً فقط از فیلدهای پایدار ThemeData استفاده شده تا با
// نسخه‌های مختلف Flutter سازگار بماند.

import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color brandBlue = Color(0xFF1666C5);
  static const Color brandTeal = Color(0xFF14B2A7);
  static const Color brandOrange = Color(0xFFFF8A65);

  /// فونت فارسی بسته‌بندی‌شده در برنامه (Vazirmatn)
  static const String fontFamily = 'Vazirmatn';

  static const String monoFontFamily = 'Menlo';

  static const List<String> monoFallback = <String>[
    'Consolas',
    'Courier New',
    'monospace',
    'Roboto Mono',
  ];

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: const TextTheme().apply(fontFamily: fontFamily),
    );
  }

  static TextStyle monoStyle(BuildContext context, {double size = 13, Color? color}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: monoFontFamily,
      fontFamilyFallback: monoFallback,
      fontSize: size,
      height: 1.55,
      color: color ?? scheme.onSurface,
    );
  }
}
